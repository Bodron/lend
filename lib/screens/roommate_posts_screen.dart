import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/roommate_posts_api.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';
import 'messages_screen.dart';

class RoommatePostsScreen extends StatefulWidget {
  const RoommatePostsScreen({super.key});

  @override
  State<RoommatePostsScreen> createState() => _RoommatePostsScreenState();
}

class _RoommatePostsScreenState extends State<RoommatePostsScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _maxBudgetFilter = 10000.0;
  static const _defaultLocation = LatLng(44.4268, 26.1025);

  final _api = RoommatePostsApi();
  final _queryController = TextEditingController();
  RangeValues _budgetRange = const RangeValues(0, _maxBudgetFilter);
  _RoommateLocationFilter? _locationFilter;
  Timer? _filterDebounce;
  late Future<List<RoommatePost>> _postsFuture = _loadPosts();

  RoommatePostFilters get _filters => RoommatePostFilters(
    query: _queryController.text,
    minBudget: _budgetRange.start > 0
        ? _budgetRange.start.round().toString()
        : '',
    maxBudget: _budgetRange.end < _maxBudgetFilter
        ? _budgetRange.end.round().toString()
        : '',
    latitude: _locationFilter?.position.latitude,
    longitude: _locationFilter?.position.longitude,
    radiusKm: _locationFilter?.radiusKm,
  );

  Future<List<RoommatePost>> _loadPosts() {
    return _api.findAll(filters: _filters);
  }

  void _reload() {
    setState(() {
      _postsFuture = _loadPosts();
    });
  }

  void _queueFilterReload() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 450), _reload);
  }

  void _clearFilters() {
    _filterDebounce?.cancel();
    _queryController.clear();
    _budgetRange = const RangeValues(0, _maxBudgetFilter);
    _locationFilter = null;
    _reload();
  }

  void _setBudgetRange(RangeValues value) {
    setState(() {
      _budgetRange = RangeValues(
        value.start.roundToDouble(),
        value.end.roundToDouble(),
      );
    });
    _queueFilterReload();
  }

  Future<void> _openLocationSheet() async {
    final result = await showModalBottomSheet<_RoommateLocationFilter?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _RoommateLocationSheet(
        initialFilter:
            _locationFilter ??
            const _RoommateLocationFilter(
              position: _defaultLocation,
              radiusKm: 25,
              label: 'Bucuresti, Romania',
            ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _locationFilter = result.enabled ? result : null;
    });
    _reload();
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendInterest(RoommatePost post) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _InterestSheet(post: post),
    );

    if (message == null) {
      return;
    }

    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) {
        throw RoommatePostsApiException('Trebuie sa fii autentificat.');
      }

      final result = await _api.sendInterest(
        accessToken: token,
        postId: post.id,
        message: message,
      );

      if (!mounted) return;
      final openedChat = await _openChatForPost(
        post,
        productId: result.productId,
        roommateInterestId: result.interestId,
      );
      if (!mounted) return;
      if (!openedChat) {
        LendToast.info(context, message: 'Cererea a fost trimisa.');
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (message.contains('Ai trimis deja')) {
        final openedChat = await _openChatForPost(post);
        if (openedChat || !mounted) {
          return;
        }
      }
      LendToast.info(context, message: error.toString());
    }
  }

  Future<bool> _openChatForPost(
    RoommatePost post, {
    String? productId,
    String? roommateInterestId,
  }) async {
    final targetProductId = productId ?? post.product?.id;
    if (targetProductId == null || targetProductId.isEmpty) {
      return false;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ProductChatScreen(
          productId: targetProductId,
          roommateInterestId: roommateInterestId,
          contextLabel: 'Cerere caut coleg',
          productTitle: post.product?.title ?? post.title,
          ownerName: post.authorName,
        ),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: LendScreenFrame(
            backgroundColor: _background,
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _postsFuture;
              },
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _RoommateTopBar()),
                  SliverToBoxAdapter(
                    child: _RoommateFilters(
                      queryController: _queryController,
                      budgetRange: _budgetRange,
                      maxBudget: _maxBudgetFilter,
                      locationFilter: _locationFilter,
                      hasFilters: !_filters.isEmpty,
                      onChanged: _queueFilterReload,
                      onBudgetChanged: _setBudgetRange,
                      onLocationTap: _openLocationSheet,
                      onClear: _clearFilters,
                    ),
                  ),
                  FutureBuilder<List<RoommatePost>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: _text),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          child: _RoommateError(onRetry: _reload),
                        );
                      }

                      final posts = snapshot.data ?? const <RoommatePost>[];
                      if (posts.isEmpty) {
                        return const SliverFillRemaining(
                          child: _EmptyRoommatePosts(),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
                        sliver: SliverList.separated(
                          itemCount: posts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return _RoommatePostCard(
                              post: post,
                              onInterest: () => _sendInterest(post),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoommatePostScreen extends StatefulWidget {
  const CreateRoommatePostScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<CreateRoommatePostScreen> createState() =>
      _CreateRoommatePostScreenState();
}

class _CreateRoommatePostScreenState extends State<CreateRoommatePostScreen> {
  static const _primary = _RoommatePostsScreenState._primary;
  static const _background = _RoommatePostsScreenState._background;

  final _api = RoommatePostsApi();
  late final TextEditingController _titleController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _budgetController;
  late final TextEditingController _moveInController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _preferencesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(
      text: 'Caut coleg pentru ${product.title}',
    );
    _cityController = TextEditingController(text: product.city);
    _areaController = TextEditingController(text: product.address);
    _budgetController = TextEditingController(
      text: product.pricePerMonth?.toString() ?? '',
    );
    _moveInController = TextEditingController();
    _descriptionController = TextEditingController();
    _preferencesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _moveInController.dispose();
    _descriptionController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    final city = _cityController.text.trim();
    final area = _areaController.text.trim();
    final budget = int.tryParse(_budgetController.text.trim()) ?? 0;
    final moveIn = _moveInController.text.trim();
    final description = _descriptionController.text.trim();
    final preferences = _preferencesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (title.isEmpty || city.isEmpty || budget <= 0 || description.isEmpty) {
      LendToast.info(
        context,
        message: 'Completeaza titlul, orasul, bugetul si descrierea.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) {
        throw RoommatePostsApiException('Trebuie sa fii autentificat.');
      }

      await _api.create(
        accessToken: token,
        input: RoommatePostInput(
          productId: widget.product.id,
          title: title,
          city: city,
          area: area,
          budgetPerMonth: budget,
          moveInDate: moveIn,
          description: description,
          preferences: preferences,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      LendToast.info(context, message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: LendScreenFrame(
            backgroundColor: _background,
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _CreateRoommateTopBar()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _AttachedProductCard(product: widget.product),
                          const SizedBox(height: 20),
                          _RoommateField(
                            controller: _titleController,
                            label: 'Titlu',
                            hint: 'Caut coleg/colega in Cluj',
                            readOnly: true,
                          ),
                          _RoommateField(
                            controller: _cityController,
                            label: 'Oras',
                            hint: 'Bucuresti',
                            readOnly: true,
                          ),
                          _RoommateField(
                            controller: _areaController,
                            label: 'Zona',
                            hint: 'Unirii, Marasti, Copou...',
                            readOnly: true,
                          ),
                          _RoommateField(
                            controller: _budgetController,
                            label: 'Buget lunar',
                            hint: '1500',
                            suffix: 'RON',
                            keyboardType: TextInputType.number,
                            readOnly: true,
                          ),
                          _RoommateField(
                            controller: _moveInController,
                            label: 'Mutare',
                            hint: 'Octombrie / cat mai repede',
                          ),
                          _RoommateField(
                            controller: _preferencesController,
                            label: 'Preferinte',
                            hint: 'nefumator, student, pet friendly',
                          ),
                          _RoommateField(
                            controller: _descriptionController,
                            label: 'Descriere',
                            hint: 'Spune cum esti ca viitor coleg si ce cauti.',
                            maxLines: 5,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      MediaQuery.paddingOf(context).bottom + 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: _RoommatePostsScreenState._outline.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.group_add_rounded),
                        label: Text(
                          _submitting ? 'Se publica...' : 'Publica anuntul',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoommateTopBar extends StatelessWidget {
  const _RoommateTopBar();

  @override
  Widget build(BuildContext context) {
    return const LendBackTopBar(title: 'Caut coleg');
  }
}

class _RoommateFilters extends StatelessWidget {
  const _RoommateFilters({
    required this.queryController,
    required this.budgetRange,
    required this.maxBudget,
    required this.locationFilter,
    required this.hasFilters,
    required this.onChanged,
    required this.onBudgetChanged,
    required this.onLocationTap,
    required this.onClear,
  });

  final TextEditingController queryController;
  final RangeValues budgetRange;
  final double maxBudget;
  final _RoommateLocationFilter? locationFilter;
  final bool hasFilters;
  final VoidCallback onChanged;
  final ValueChanged<RangeValues> onBudgetChanged;
  final VoidCallback onLocationTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: DecoratedBox(
        decoration: _roommateCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _FilterField(
                controller: queryController,
                hint: 'Cautare',
                icon: Icons.search_rounded,
                onChanged: onChanged,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onLocationTap,
                  icon: const Icon(Icons.location_on_rounded, size: 19),
                  label: Text(
                    locationFilter == null
                        ? 'Locatie'
                        : '${locationFilter!.label ?? 'Locatie'} · ${locationFilter!.radiusKm.round()} km',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: locationFilter == null
                        ? _RoommatePostsScreenState._text
                        : _RoommatePostsScreenState._primary,
                    side: BorderSide(
                      color:
                          (locationFilter == null
                                  ? _RoommatePostsScreenState._outline
                                  : _RoommatePostsScreenState._primary)
                              .withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _BudgetRangeFilter(
                range: budgetRange,
                maxBudget: maxBudget,
                onChanged: onBudgetChanged,
              ),
              if (hasFilters) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Sterge filtrele'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _RoommatePostsScreenState._primary,
                      side: BorderSide(
                        color: _RoommatePostsScreenState._primary.withValues(
                          alpha: 0.28,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetRangeFilter extends StatelessWidget {
  const _BudgetRangeFilter({
    required this.range,
    required this.maxBudget,
    required this.onChanged,
  });

  final RangeValues range;
  final double maxBudget;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final start = range.start.round();
    final end = range.end.round();
    final endLabel = end >= maxBudget.round() ? '$end+' : end.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.payments_rounded,
              size: 20,
              color: _RoommatePostsScreenState._primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Pret lunar',
                style: TextStyle(
                  color: _RoommatePostsScreenState._text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$start - $endLabel RON',
              style: const TextStyle(
                color: _RoommatePostsScreenState._muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: range,
          min: 0,
          max: maxBudget,
          divisions: (maxBudget / 100).round(),
          labels: RangeLabels('$start RON', '$endLabel RON'),
          activeColor: _RoommatePostsScreenState._primary,
          inactiveColor: _RoommatePostsScreenState._primary.withValues(
            alpha: 0.16,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RoommateLocationFilter {
  const _RoommateLocationFilter({
    required this.position,
    required this.radiusKm,
    this.label,
    this.enabled = true,
  });

  final LatLng position;
  final double radiusKm;
  final String? label;
  final bool enabled;
}

class _RoommateLocationSheet extends StatefulWidget {
  const _RoommateLocationSheet({required this.initialFilter});

  final _RoommateLocationFilter initialFilter;

  @override
  State<_RoommateLocationSheet> createState() => _RoommateLocationSheetState();
}

class _RoommateLocationSheetState extends State<_RoommateLocationSheet> {
  late LatLng _position = widget.initialFilter.position;
  late double _radiusKm = widget.initialFilter.radiusKm;
  GoogleMapController? _controller;
  String? _mapStyle;
  String? _locationLabel;
  bool _resolvingLocation = false;
  Timer? _reverseGeocodeDebounce;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/maps/altus_map_3.json').then((style) {
      if (mounted) {
        setState(() => _mapStyle = style);
      }
    });
    _locationLabel = widget.initialFilter.label;
    _resolveLocationLabel();
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _setPosition(LatLng position) {
    setState(() {
      _position = position;
      _locationLabel = null;
    });
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(
      const Duration(milliseconds: 450),
      _resolveLocationLabel,
    );
  }

  Future<void> _resolveLocationLabel() async {
    setState(() => _resolvingLocation = true);

    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(_position.latitude, _position.longitude)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;

      final place = placemarks.isEmpty ? null : placemarks.first;
      final city =
          [
                place?.locality,
                place?.subAdministrativeArea,
                place?.administrativeArea,
              ]
              .whereType<String>()
              .map((value) => value.trim())
              .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      final country = place?.country?.trim() ?? '';
      final label = [
        city,
        country,
      ].where((value) => value.isNotEmpty).join(', ');

      setState(() {
        _locationLabel = label.isEmpty ? null : label;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLabel = null);
    } finally {
      if (mounted) {
        setState(() => _resolvingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final radius = _radiusKm.round();

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottomPadding + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtru locatie',
                      style: TextStyle(
                        color: _RoommatePostsScreenState._text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resolvingLocation
                          ? 'Detectez orasul...'
                          : (_locationLabel ?? 'Muta pinul pe orasul dorit'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RoommatePostsScreenState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 320,
              child: GoogleMap(
                style: _mapStyle,
                initialCameraPosition: CameraPosition(
                  target: _position,
                  zoom: 11,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('roommate-location-filter'),
                    position: _position,
                    draggable: true,
                    onDragEnd: _setPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
                circles: {
                  Circle(
                    circleId: const CircleId('roommate-location-radius'),
                    center: _position,
                    radius: _radiusKm * 1000,
                    fillColor: _RoommatePostsScreenState._primary.withValues(
                      alpha: 0.12,
                    ),
                    strokeColor: _RoommatePostsScreenState._primary.withValues(
                      alpha: 0.45,
                    ),
                    strokeWidth: 2,
                  ),
                },
                onTap: _setPosition,
                onMapCreated: (controller) => _controller = controller,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                size: 20,
                color: _RoommatePostsScreenState._primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Raza cautare',
                  style: TextStyle(
                    color: _RoommatePostsScreenState._text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$radius km',
                style: const TextStyle(
                  color: _RoommatePostsScreenState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 100,
            divisions: 99,
            label: '$radius km',
            activeColor: _RoommatePostsScreenState._primary,
            inactiveColor: _RoommatePostsScreenState._primary.withValues(
              alpha: 0.16,
            ),
            onChanged: (value) {
              setState(() => _radiusKm = value.roundToDouble());
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    _RoommateLocationFilter(
                      position: _position,
                      radiusKm: _radiusKm,
                      label: _locationLabel,
                      enabled: false,
                    ),
                  ),
                  icon: const Icon(Icons.location_off_rounded, size: 18),
                  label: const Text('Scoate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _RoommatePostsScreenState._muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    _RoommateLocationFilter(
                      position: _position,
                      radiusKm: _radiusKm,
                      label: _locationLabel,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Aplica'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _RoommatePostsScreenState._primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F5F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: _RoommatePostsScreenState._outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: _RoommatePostsScreenState._outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: _RoommatePostsScreenState._primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateRoommateTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const LendBackTopBar(title: 'Anunt de coleg');
  }
}

class _RoommatePostCard extends StatelessWidget {
  const _RoommatePostCard({required this.post, required this.onInterest});

  final RoommatePost post;
  final VoidCallback onInterest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _roommateCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD5E3FF),
                  foregroundColor: _RoommatePostsScreenState._text,
                  backgroundImage: post.authorAvatarUrl == null
                      ? null
                      : NetworkImage(post.authorAvatarUrl!),
                  child: post.authorAvatarUrl == null
                      ? Text(post.authorName.isEmpty ? '?' : post.authorName[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _RoommatePostsScreenState._text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          post.city,
                          post.area,
                        ].where((value) => value.isNotEmpty).join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _RoommatePostsScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _BudgetPill(text: post.budgetLabel),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.title,
              style: const TextStyle(
                color: _RoommatePostsScreenState._text,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(
                color: _RoommatePostsScreenState._muted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (post.preferences.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preference in post.preferences)
                    _PreferenceChip(text: preference),
                ],
              ),
            ],
            if (post.product != null) ...[
              const SizedBox(height: 14),
              _RoommateProductStrip(product: post.product!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onInterest,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Sunt interesat'),
                style: FilledButton.styleFrom(
                  backgroundColor: _RoommatePostsScreenState._primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoommateProductStrip extends StatelessWidget {
  const _RoommateProductStrip({required this.product});

  final RoommatePostProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 58,
              height: 58,
              child: product.imageUrl.isEmpty
                  ? const ColoredBox(color: Color(0xFFD5E3FF))
                  : Image.network(product.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _RoommatePostsScreenState._text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    color: _RoommatePostsScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachedProductCard extends StatelessWidget {
  const _AttachedProductCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _roommateCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 70,
                child: product.imageUrl.isEmpty
                    ? const ColoredBox(color: Color(0xFFD5E3FF))
                    : Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apartament atasat',
                    style: TextStyle(
                      color: _RoommatePostsScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RoommatePostsScreenState._text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestSheet extends StatefulWidget {
  const _InterestSheet({required this.post});

  final RoommatePost post;

  @override
  State<_InterestSheet> createState() => _InterestSheetState();
}

class _InterestSheetState extends State<_InterestSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 6, 20, 20 + keyboardInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scrie-i lui ${widget.post.authorName}',
                style: const TextStyle(
                  color: _RoommatePostsScreenState._text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                decoration: _roommateInputDecoration(
                  'Salut! Sunt interesat de anuntul tau...',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: _RoommatePostsScreenState._primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Trimite cererea'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoommateField extends StatelessWidget {
  const _RoommateField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _RoommatePostsScreenState._muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            enableInteractiveSelection: !readOnly,
            decoration: _roommateInputDecoration(
              hint,
              readOnly: readOnly,
            ).copyWith(suffixText: suffix),
          ),
        ],
      ),
    );
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _RoommatePostsScreenState._primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _RoommatePostsScreenState._primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD5E3FF).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _RoommatePostsScreenState._text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoommateError extends StatelessWidget {
  const _RoommateError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nu am putut incarca anunturile de colegi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RoommatePostsScreenState._muted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _RoommatePostsScreenState._primary,
              ),
              child: const Text('Reincearca'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoommatePosts extends StatelessWidget {
  const _EmptyRoommatePosts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nu exista inca anunturi de colegi. Fii primul care publica unul.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RoommatePostsScreenState._muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

InputDecoration _roommateInputDecoration(String hint, {bool readOnly = false}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: readOnly ? const Color(0xFFF1F2F5) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RoommatePostsScreenState._outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RoommatePostsScreenState._outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: _RoommatePostsScreenState._text,
        width: 1.4,
      ),
    ),
  );
}

final _roommateCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);
