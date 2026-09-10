import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, SystemUiOverlayStyle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:video_player/video_player.dart';

import '../l10n/generated_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/storage_api.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/lend_toast.dart';
import 'main_shell.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key, this.initialData});

  final ListingFormData? initialData;

  bool get isEditing => initialData != null;

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class ListingFormData {
  const ListingFormData({
    this.productId,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.imageUrl,
    this.category = 'choose',
    this.categoryLabel = '',
    this.deposit = '0',
    this.city = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.media = const [],
    this.pricePerHour = '',
    this.pickupTime = '10:00',
    this.returnTime = '18:00',
  });

  final String? productId;
  final String title;
  final String description;
  final String pricePerDay;
  final String pricePerHour;
  final String imageUrl;
  final String category;
  final String categoryLabel;
  final String deposit;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final List<UploadedMedia> media;
  final String pickupTime;
  final String returnTime;
}

class _AddListingScreenState extends State<AddListingScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF9F9F9);
  static const _card = Colors.white;
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _secondary = Color(0xFF446085);
  static const _secondaryContainer = Color(0xFFB7D3FE);
  static const _primaryFixed = Color(0xFFD5E3FF);
  static const _bucharest = LatLng(44.4268, 26.1025);

  bool _insuranceEnabled = true;
  bool _hourlyEnabled = true;
  bool _dailyEnabled = true;
  bool _monthlyEnabled = false;
  Timer? _addressDebounce;
  String _category = 'choose';
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pricePerDayController;
  late final TextEditingController _pricePerHourController;
  late final TextEditingController _pricePerMonthController;
  late final TextEditingController _depositController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _pickupTimeController;
  late final TextEditingController _returnTimeController;
  final _productsApi = ProductsApi();
  final _storageApi = StorageApi();
  final List<_SelectedMedia> _selectedMedia = [];
  LatLng _selectedLocation = _bucharest;
  String? _mapStyle;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    _category = _supportedCategory(initialData?.category ?? 'choose');
    _titleController = TextEditingController(text: initialData?.title ?? '');
    _descriptionController = TextEditingController(
      text: initialData?.description ?? '',
    );
    _pricePerDayController = TextEditingController(
      text: initialData?.pricePerDay ?? '',
    );
    _pricePerHourController = TextEditingController(
      text: initialData?.pricePerHour ?? '',
    );
    _pricePerMonthController = TextEditingController();
    _depositController = TextEditingController(
      text: initialData?.deposit ?? '0',
    );
    _cityController = TextEditingController(
      text: initialData?.city.isNotEmpty == true
          ? initialData!.city
          : 'Bucuresti',
    );
    _addressController = TextEditingController(
      text: initialData?.address ?? '',
    );
    _addressController.addListener(_geocodeAddress);
    _pickupTimeController = TextEditingController(
      text: initialData?.pickupTime ?? '10:00',
    );
    _returnTimeController = TextEditingController(
      text: initialData?.returnTime ?? '18:00',
    );
    if (initialData?.latitude != null && initialData?.longitude != null) {
      _selectedLocation = LatLng(
        initialData!.latitude!,
        initialData.longitude!,
      );
    } else {
      _selectedLocation = _cityCenterFor(_cityController.text);
    }
    _loadMapStyle();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _pricePerHourController.dispose();
    _pricePerMonthController.dispose();
    _depositController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _addressDebounce?.cancel();
    _pickupTimeController.dispose();
    _returnTimeController.dispose();
    super.dispose();
  }

  void _geocodeAddress() {
    _addressDebounce?.cancel();
    final address = _addressController.text.trim();
    if (address.length < 5) return;
    _addressDebounce = Timer(const Duration(milliseconds: 700), () async {
      try {
        final query = '$address, ${_cityController.text.trim()}, Romania';
        final locations = await Geocoding().locationFromAddress(query);
        if (!mounted || locations.isEmpty) return;
        final location = locations.first;
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });
      } catch (_) {
        // Utilizatorul poate ajusta pinul manual dacă adresa nu este găsită.
      }
    });
  }

  Future<void> _loadMapStyle() async {
    final mapStyle = await rootBundle.loadString(
      'assets/maps/altus_map_3.json',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _mapStyle = mapStyle;
    });
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'],
      withData: true,
    );

    if (result == null) {
      return;
    }

    final nextItems = result.files
        .where((file) => file.bytes != null)
        .map(_SelectedMedia.fromPlatformFile)
        .where((media) => media.contentType != 'application/octet-stream')
        .toList();

    setState(() {
      final remainingSlots = 8 - _selectedMedia.length;
      _selectedMedia.addAll(nextItems.take(remainingSlots));
    });
  }

  void _removeMedia(_SelectedMedia media) {
    setState(() {
      _selectedMedia.remove(media);
    });
  }

  Future<void> _submitListing() async {
    if (_submitting) {
      return;
    }

    final strings = GeneratedLocalizations.of(context);

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final pricePerDay = int.tryParse(_pricePerDayController.text.trim()) ?? 0;
    final pricePerMonth =
        int.tryParse(_pricePerMonthController.text.trim()) ?? 0;
    final deposit = int.tryParse(_depositController.text.trim()) ?? 0;
    final city = _cityController.text.trim();
    final address = _addressController.text.trim();
    final pickupTime = _pickupTimeController.text.trim();
    final returnTime = _returnTimeController.text.trim();
    final category = _categoryLabel(_category);

    if (title.isEmpty ||
        description.isEmpty ||
        pricePerDay <= 0 ||
        city.isEmpty ||
        address.isEmpty ||
        _category == 'choose' ||
        (!_hourlyEnabled && !_dailyEnabled && !_monthlyEnabled) ||
        (_monthlyEnabled && pricePerMonth <= 0) ||
        !_isValidTime(pickupTime) ||
        !_isValidTime(returnTime)) {
      _showMessage(GeneratedLocalizations.of(context).listingFormInvalid);
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final token = await AuthSessionStore.getToken();

      if (token == null) {
        throw AuthApiException(strings.signInRequired);
      }

      final uploadedMedia = <UploadedMedia>[
        ...(widget.initialData?.media ?? const <UploadedMedia>[]),
      ];
      for (final media in _selectedMedia) {
        uploadedMedia.add(
          await _storageApi.uploadMedia(
            accessToken: token,
            fileName: media.fileName,
            contentType: media.contentType,
            bytes: media.bytes,
            alt: title,
          ),
        );
      }

      final input = ProductSaveInput(
        title: title,
        category: category,
        categorySlug: _category,
        description: description,
        pricePerDay: pricePerDay,
        pricePerMonth: _monthlyEnabled ? pricePerMonth : null,
        deposit: deposit,
        city: city,
        address: address,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        pickupTime: pickupTime,
        returnTime: returnTime,
        rentalModes: [
          if (_hourlyEnabled) 'hour',
          if (_dailyEnabled) 'day',
          if (_monthlyEnabled) 'month',
        ],
        media: uploadedMedia,
      );

      if (widget.isEditing) {
        final productId = widget.initialData?.productId;

        if (productId == null || productId.isEmpty) {
          throw ProductsApiException(strings.missingProductIdForEdit);
        }

        await _productsApi.update(
          accessToken: token,
          productId: productId,
          input: input,
        );
      } else {
        await _productsApi.create(accessToken: token, input: input);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const MainShell(initialIndex: 1),
        ),
      );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    LendToast.info(context, message: message);
  }

  bool _isValidTime(String value) {
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  String _categoryLabel(String value) {
    final strings = GeneratedLocalizations.of(context);

    return switch (value) {
      'tools' => strings.toolsDiy,
      'unelte' => strings.tools,
      'home' => strings.homeGarden,
      'electronics' || 'electronice' => strings.electronics,
      'sport' || 'sport-outdoor' => strings.sportOutdoor,
      'gaming-console' => strings.gamingConsole,
      'foto-video' => strings.photoVideo,
      'drone' => strings.drones,
      _ => strings.other,
    };
  }

  String _supportedCategory(String value) {
    const supported = {
      'choose',
      'unelte',
      'electronice',
      'sport-outdoor',
      'gaming-console',
      'foto-video',
      'drone',
      'tools',
      'home',
      'electronics',
      'sport',
    };

    return supported.contains(value) ? value : 'choose';
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _centerPinOnCity() {
    setState(() {
      _selectedLocation = _cityCenterFor(_cityController.text);
    });
  }

  static LatLng _cityCenterFor(String city) {
    final normalizedCity = city
        .trim()
        .toLowerCase()
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't');

    return _listingCityCoordinates[normalizedCity] ?? _bucharest;
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
          child: ColoredBox(
            color: _background,
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _AddListingTopBar(isEditing: widget.isEditing),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 144),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const _TrustBanner(),
                          const SizedBox(height: 32),
                          _PhotosSection(
                            imageUrl: widget.initialData?.imageUrl,
                            selectedMedia: _selectedMedia,
                            onPickMedia: _pickMedia,
                            onRemoveMedia: _removeMedia,
                          ),
                          const SizedBox(height: 32),
                          _BasicInfoSection(
                            category: _category,
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            cityController: _cityController,
                            addressController: _addressController,
                            selectedLocation: _selectedLocation,
                            mapStyle: _mapStyle,
                            onCategoryChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _category = value;
                              });
                            },
                            onLocationChanged: _selectLocation,
                            onCenterPinOnCity: _centerPinOnCity,
                          ),
                          const SizedBox(height: 32),
                          _RatesSection(
                            pricePerHourController: _pricePerHourController,
                            pricePerDayController: _pricePerDayController,
                            pricePerMonthController: _pricePerMonthController,
                            depositController: _depositController,
                            pickupTimeController: _pickupTimeController,
                            returnTimeController: _returnTimeController,
                            hourlyEnabled: _hourlyEnabled,
                            dailyEnabled: _dailyEnabled,
                            monthlyEnabled: _monthlyEnabled,
                            onHourlyChanged: (value) =>
                                setState(() => _hourlyEnabled = value),
                            onDailyChanged: (value) =>
                                setState(() => _dailyEnabled = value),
                            onMonthlyChanged: (value) =>
                                setState(() => _monthlyEnabled = value),
                          ),
                          const SizedBox(height: 24),
                          _InsuranceCard(
                            enabled: _insuranceEnabled,
                            onChanged: (value) {
                              setState(() {
                                _insuranceEnabled = value;
                              });
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _BottomActions(
                    isEditing: widget.isEditing,
                    submitting: _submitting,
                    onSubmit: _submitListing,
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

class _AddListingTopBar extends StatelessWidget {
  const _AddListingTopBar({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _AddListingScreenState._background.withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: _AddListingScreenState._outline.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _AddListingScreenState._text,
          ),
          Expanded(
            child: Text(
              isEditing ? strings.editListing : strings.addListing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AddListingScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const LanguageToggleButton(),
          const SizedBox(width: 8),
          _SecurePill(label: strings.secure),
        ],
      ),
    );
  }
}

class _SecurePill extends StatelessWidget {
  const _SecurePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _AddListingScreenState._primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AddListingScreenState._primary.withValues(alpha: 0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: _AddListingScreenState._text,
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _AddListingScreenState._text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _AddListingScreenState._secondaryContainer.withValues(
          alpha: 0.30,
        ),
        border: Border.all(color: _AddListingScreenState._secondaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: _AddListingScreenState._secondary,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.shield_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.coveredByLend,
                    style: const TextStyle(
                      color: Color(0xFF2B486C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.coveredByLendBody,
                    style: const TextStyle(
                      color: _AddListingScreenState._muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
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

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    this.imageUrl,
    required this.selectedMedia,
    required this.onPickMedia,
    required this.onRemoveMedia,
  });

  final String? imageUrl;
  final List<_SelectedMedia> selectedMedia;
  final VoidCallback onPickMedia;
  final ValueChanged<_SelectedMedia> onRemoveMedia;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return _Section(
      title: strings.photos,
      trailing: strings.maxEightFiles,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / 2;
          final existingImageUrl = imageUrl;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: itemWidth,
                height: itemWidth,
                child: OutlinedButton(
                  onPressed: onPickMedia,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AddListingScreenState._muted,
                    side: const BorderSide(
                      color: _AddListingScreenState._outline,
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: _AddListingScreenState._primaryFixed,
                        child: Icon(
                          Icons.camera_enhance_rounded,
                          color: _AddListingScreenState._text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.addMedia,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedMedia.isEmpty && existingImageUrl?.isNotEmpty == true)
                SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      existingImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(color: Color(0xFFE2E2E2));
                      },
                    ),
                  ),
                ),
              for (final media in selectedMedia)
                _SelectedMediaTile(
                  media: media,
                  size: itemWidth,
                  onRemove: () => onRemoveMedia(media),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedMediaTile extends StatelessWidget {
  const _SelectedMediaTile({
    required this.media,
    required this.size,
    required this.onRemove,
  });

  final _SelectedMedia media;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: media.isVideo
                ? _VideoMediaPreview(media: media)
                : Image.memory(media.bytes, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoMediaPreview extends StatefulWidget {
  const _VideoMediaPreview({required this.media});

  final _SelectedMedia media;

  @override
  State<_VideoMediaPreview> createState() => _VideoMediaPreviewState();
}

class _VideoMediaPreviewState extends State<_VideoMediaPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    final path = widget.media.path;

    if (path == null || path.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    _initializeFuture = controller.initialize().then((_) async {
      await controller.seekTo(Duration.zero);
      await controller.pause();

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null) {
      return _VideoFallbackPreview(fileName: widget.media.fileName);
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !controller.value.isInitialized) {
          return _VideoFallbackPreview(fileName: widget.media.fileName);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            _VideoFrame(controller: controller),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.50),
                  ],
                ),
              ),
            ),
            const Positioned(left: 12, top: 12, child: _VideoBadge(dark: true)),
            const Center(child: _PlayOverlay()),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                widget.media.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;

    if (size.width <= 0 || size.height <= 0) {
      return const ColoredBox(color: Color(0xFFD5E3FF));
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _VideoFallbackPreview extends StatelessWidget {
  const _VideoFallbackPreview({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD5E3FF), Color(0xFFB7D3FE)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -24,
            bottom: -18,
            child: Icon(
              Icons.movie_creation_outlined,
              size: 112,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _VideoBadge(),
                const Spacer(),
                const Center(child: _PlayOverlay()),
                const Spacer(),
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AddListingScreenState._text,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
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

class _VideoBadge extends StatelessWidget {
  const _VideoBadge({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.92 : 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              color: _AddListingScreenState._text,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              strings.videoLabel,
              style: TextStyle(
                color: _AddListingScreenState._text,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: _AddListingScreenState._text,
        size: 34,
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({
    required this.category,
    required this.titleController,
    required this.descriptionController,
    required this.cityController,
    required this.addressController,
    required this.selectedLocation,
    required this.mapStyle,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onCenterPinOnCity,
  });

  final String category;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final LatLng selectedLocation;
  final String? mapStyle;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<LatLng> onLocationChanged;
  final VoidCallback onCenterPinOnCity;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return _TitledFormSection(
      icon: Icons.info_outline_rounded,
      title: strings.basicInformation,
      children: [
        _LabeledField(
          controller: titleController,
          label: strings.itemName,
          hint: strings.itemNameHint,
        ),
        _LabeledDropdown(
          label: strings.category,
          value: category,
          values: const [
            'choose',
            'unelte',
            'electronice',
            'sport-outdoor',
            'gaming-console',
            'foto-video',
            'drone',
            'tools',
            'home',
            'electronics',
            'sport',
          ],
          labelForValue: (value) => switch (value) {
            'tools' => strings.toolsDiy,
            'unelte' => strings.tools,
            'home' => strings.homeGarden,
            'electronics' || 'electronice' => strings.electronics,
            'sport' || 'sport-outdoor' => strings.sportOutdoor,
            'gaming-console' => strings.gamingConsole,
            'foto-video' => strings.photoVideo,
            'drone' => strings.drones,
            _ => strings.chooseCategory,
          },
          onChanged: onCategoryChanged,
        ),
        _LabeledField(
          controller: cityController,
          label: strings.city,
          hint: strings.cityHint,
        ),
        _LabeledField(
          controller: addressController,
          label: strings.address,
          hint: strings.addressHint,
        ),
        _LocationPicker(
          selectedLocation: selectedLocation,
          mapStyle: mapStyle,
          onLocationChanged: onLocationChanged,
          onCenterPinOnCity: onCenterPinOnCity,
        ),
        _LabeledField(
          controller: descriptionController,
          label: strings.description,
          hint: strings.descriptionHint,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({
    required this.selectedLocation,
    required this.mapStyle,
    required this.onLocationChanged,
    required this.onCenterPinOnCity,
  });

  final LatLng selectedLocation;
  final String? mapStyle;
  final ValueChanged<LatLng> onLocationChanged;
  final VoidCallback onCenterPinOnCity;

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant _LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(widget.selectedLocation),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _FieldLabel(strings.mapPin)),
            TextButton.icon(
              onPressed: widget.onCenterPinOnCity,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(strings.centerOnCity),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              style: widget.mapStyle,
              initialCameraPosition: CameraPosition(
                target: widget.selectedLocation,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('listing-location'),
                  position: widget.selectedLocation,
                  draggable: true,
                  onDragEnd: widget.onLocationChanged,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
              onMapCreated: (controller) {
                _controller = controller;
              },
              onTap: widget.onLocationChanged,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.mapPinHelp,
          style: const TextStyle(
            color: _AddListingScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RatesSection extends StatelessWidget {
  const _RatesSection({
    required this.pricePerHourController,
    required this.pricePerDayController,
    required this.pricePerMonthController,
    required this.depositController,
    required this.pickupTimeController,
    required this.returnTimeController,
    required this.hourlyEnabled,
    required this.dailyEnabled,
    required this.monthlyEnabled,
    required this.onHourlyChanged,
    required this.onDailyChanged,
    required this.onMonthlyChanged,
  });

  final TextEditingController pricePerHourController;
  final TextEditingController pricePerDayController;
  final TextEditingController pricePerMonthController;
  final TextEditingController depositController;
  final TextEditingController pickupTimeController;
  final TextEditingController returnTimeController;
  final bool hourlyEnabled;
  final bool dailyEnabled;
  final bool monthlyEnabled;
  final ValueChanged<bool> onHourlyChanged;
  final ValueChanged<bool> onDailyChanged;
  final ValueChanged<bool> onMonthlyChanged;

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final current = controller.text.split(':');
    final initial = current.length == 2
        ? TimeOfDay(
            hour: int.tryParse(current[0]) ?? 10,
            minute: int.tryParse(current[1]) ?? 0,
          )
        : const TimeOfDay(hour: 10, minute: 0);
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected != null) {
      controller.text =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return _TitledFormSection(
      icon: Icons.payments_outlined,
      title: strings.rates,
      children: [
        _RentalPriceRow(
          label: strings.hourly,
          priceLabel: strings.pricePerHour,
          controller: pricePerHourController,
          selected: hourlyEnabled,
          onChanged: onHourlyChanged,
        ),
        const SizedBox(height: 4),
        _RentalPriceRow(
          label: strings.daily,
          priceLabel: strings.pricePerDay,
          controller: pricePerDayController,
          selected: dailyEnabled,
          onChanged: onDailyChanged,
        ),
        const SizedBox(height: 4),
        _RentalPriceRow(
          label: strings.monthly,
          priceLabel: strings.pricePerMonth,
          controller: pricePerMonthController,
          selected: monthlyEnabled,
          onChanged: onMonthlyChanged,
        ),
        const SizedBox(height: 16),
        if (_shouldShowLegacyLayout()) ...[
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.hourly),
                  value: hourlyEnabled,
                  onChanged: (v) {
                    if (v != null) onHourlyChanged(v);
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.daily),
                  value: dailyEnabled,
                  onChanged: (v) {
                    if (v != null) onDailyChanged(v);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (hourlyEnabled)
                Expanded(
                  child: _LabeledField(
                    controller: pricePerHourController,
                    label: strings.pricePerHour,
                    hint: '0.00',
                    suffix: 'RON',
                    keyboardType: TextInputType.number,
                  ),
                ),
              if (hourlyEnabled && dailyEnabled) const SizedBox(width: 14),
              if (dailyEnabled)
                Expanded(
                  child: _LabeledField(
                    controller: pricePerDayController,
                    label: strings.pricePerDay,
                    hint: '0.00',
                    suffix: 'RON',
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
        ],
        _LabeledField(
          controller: depositController,
          label: strings.deposit,
          hint: '0.00',
          suffix: 'RON',
          keyboardType: TextInputType.number,
        ),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                controller: pickupTimeController,
                label: strings.pickupAfter,
                hint: '10:00',
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () => _selectTime(context, pickupTimeController),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _LabeledField(
                controller: returnTimeController,
                label: strings.returnBy,
                hint: '18:00',
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () => _selectTime(context, returnTimeController),
              ),
            ),
          ],
        ),
        const _SuggestionChip(),
      ],
    );
  }
}

bool _shouldShowLegacyLayout() => false;

class _RentalPriceRow extends StatelessWidget {
  const _RentalPriceRow({
    required this.label,
    required this.priceLabel,
    required this.controller,
    required this.selected,
    required this.onChanged,
  });
  final String label, priceLabel;
  final TextEditingController controller;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _AddListingScreenState._text,
          ),
        ),
        value: selected,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
      if (selected)
        _LabeledField(
          controller: controller,
          label: priceLabel,
          hint: '0.00',
          suffix: 'RON',
          keyboardType: TextInputType.number,
        ),
    ],
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _AddListingScreenState._primary.withValues(alpha: 0.05),
        border: Border.all(
          color: _AddListingScreenState._primary.withValues(alpha: 0.10),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: _AddListingScreenState._text,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                GeneratedLocalizations.of(context).pricingSuggestion,
                style: const TextStyle(
                  color: _AddListingScreenState._text,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  const _InsuranceCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _addListingCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: _AddListingScreenState._secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                GeneratedLocalizations.of(
                  context,
                ).insuranceEnabledAutomatically,
                style: const TextStyle(
                  color: _AddListingScreenState._text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: Colors.white,
              activeTrackColor: _AddListingScreenState._primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitledFormSection extends StatelessWidget {
  const _TitledFormSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: _AddListingScreenState._text),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _AddListingScreenState._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: _AddListingScreenState._outline),
        const SizedBox(height: 16),
        ...children.expand((child) => [child, const SizedBox(height: 16)]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _AddListingScreenState._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF737781),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onTap: onTap,
          readOnly: readOnly,
          decoration: _inputDecoration(hint).copyWith(suffixText: suffix),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelForValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final String Function(String value) labelForValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.expand_more_rounded),
          decoration: _inputDecoration(''),
          items: [
            for (final item in values)
              DropdownMenuItem<String>(
                value: item,
                child: Text(labelForValue(item)),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _AddListingScreenState._muted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectedMedia {
  const _SelectedMedia({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    required this.path,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final String? path;

  bool get isVideo => contentType.startsWith('video/');

  factory _SelectedMedia.fromPlatformFile(PlatformFile file) {
    return _SelectedMedia(
      fileName: file.name,
      contentType: _contentTypeFor(file.extension),
      bytes: file.bytes!,
      path: file.path,
    );
  }

  static String _contentTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      _ => 'application/octet-stream',
    };
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isEditing,
    required this.submitting,
    required this.onSubmit,
  });

  final bool isEditing;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: _AddListingScreenState._outline.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: submitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: _AddListingScreenState._primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                submitting
                    ? strings.uploading
                    : isEditing
                    ? strings.saveChanges
                    : strings.publishListing,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEditing
                ? strings.editListingBackendNote
                : strings.publishListingTermsNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF737781),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AddListingScreenState._outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AddListingScreenState._outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: _AddListingScreenState._text,
        width: 1.4,
      ),
    ),
  );
}

const _listingCityCoordinates = <String, LatLng>{
  'bucuresti': LatLng(44.4268, 26.1025),
  'bucharest': LatLng(44.4268, 26.1025),
  'cluj-napoca': LatLng(46.7712, 23.6236),
  'cluj napoca': LatLng(46.7712, 23.6236),
  'brasov': LatLng(45.6427, 25.5887),
  'timisoara': LatLng(45.7489, 21.2087),
  'iasi': LatLng(47.1585, 27.6014),
  'constanta': LatLng(44.1598, 28.6348),
  'sibiu': LatLng(45.7983, 24.1256),
  'oradea': LatLng(47.0465, 21.9189),
  'craiova': LatLng(44.3302, 23.7949),
  'galati': LatLng(45.4353, 28.0080),
  'ploiesti': LatLng(44.9367, 26.0129),
  'pitesti': LatLng(44.8565, 24.8692),
  'arad': LatLng(46.1866, 21.3123),
};

final _addListingCardDecoration = BoxDecoration(
  color: _AddListingScreenState._card,
  border: Border.all(
    color: _AddListingScreenState._outline.withValues(alpha: 0.35),
  ),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);
