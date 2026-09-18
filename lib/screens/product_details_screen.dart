import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated_localizations.dart';
import '../models/rental_mode.dart';
import '../services/products_api.dart';
import '../services/favorites_service.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/product_media_preview.dart';
import '../widgets/product_reviews_section.dart';
import 'messages_screen.dart';
import 'rental_period_screen.dart';
import 'roommate_posts_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const _primary = Color(0xFF30578F);
  static const _secondary = Color(0xFF446085);
  static const _background = Color(0xFFF9F9F9);
  static const _surfaceLow = Color(0xFFF3F3F3);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outlineVariant = Color(0xFFC3C6D1);
  static const _bucharest = LatLng(44.4268, 26.1025);

  static const _ownerImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAPgnU0_oFZ2TNOVbJqPytTt9gv2-H01VfNzs_FAujLByHdiiBrMuNQb5Z_Q_i5FDCmkBYt_se57sFT0HqRoSzbXvCti7x7DFSSFJZUvKb3Ql6bL1TxgtpdljGgWDu5IBUzPpxd_Ztl_yo1BYfrflbQliDHNGXA_to7j5gVKZIg-3uChyuKHD91dtGJCrbTFpklvdKBYW8JGFWu8BN24WPGtdALpY7eDL37sXVZv6fCl588rBrLOjl3Vr_Zz5d-ORanOp_Yu-c9tkg';

  RentalMode _rentalMode = RentalMode.day;
  bool _isFavorite = false;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _rentalMode = _hasPriceForMode(widget.product, RentalMode.hour)
        ? RentalMode.hour
        : _hasPriceForMode(widget.product, RentalMode.day)
        ? RentalMode.day
        : RentalMode.month;
    _loadMapStyle();
    FavoritesService.getIds().then((ids) {
      if (mounted) {
        setState(() => _isFavorite = ids.contains(widget.product.id));
      }
    });
  }

  static bool _hasPriceForMode(LendProduct product, RentalMode mode) {
    return switch (mode) {
      RentalMode.hour =>
        product.rentalModes.contains('hour') && product.pricePerDay > 0,
      RentalMode.day =>
        product.rentalModes.contains('day') && product.pricePerDay > 0,
      RentalMode.month =>
        product.rentalModes.contains('month') &&
            (product.pricePerMonth ?? 0) > 0,
    };
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final product = widget.product;

    return LendScreenFrame(
      backgroundColor: _background,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DetailsTopBar(
                  isFavorite: _isFavorite,
                  onFavorite: () async {
                    final value = await FavoritesService.toggle(product.id);
                    if (mounted) setState(() => _isFavorite = value);
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 116),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroImage(product: product),
                    const SizedBox(height: 8),
                    _DetailsInfoCard(
                      product: product,
                      rentalMode: _rentalMode,
                      mapStyle: _mapStyle,
                      onPriceModeChanged: (value) {
                        if (!_ProductDetailsScreenState._hasPriceForMode(
                          product,
                          value,
                        )) {
                          return;
                        }
                        setState(() {
                          _rentalMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _SpecsGrid(product: product),
                    const SizedBox(height: 24),
                    ProductReviewsSection(product: product),
                    const SizedBox(height: 24),
                    _OwnerCard(product: product),
                    const SizedBox(height: 16),
                    const _ProtectCard(),
                  ]),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomActionBar(rentalMode: _rentalMode, product: product),
          ),
        ],
      ),
    );
  }
}

class _RoommateInviteCard extends StatelessWidget {
  const _RoommateInviteCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.groups_2_rounded,
                  color: _ProductDetailsScreenState._primary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cauti coleg pentru apartamentul asta?',
                    style: TextStyle(
                      color: _ProductDetailsScreenState._text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Publica un mini-anunt atasat apartamentului si oamenii interesati iti pot trimite cerere.',
              style: TextStyle(
                color: _ProductDetailsScreenState._muted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          CreateRoommatePostScreen(product: product),
                    ),
                  );
                },
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: const Text('Cauta coleg'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ProductDetailsScreenState._primary,
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

class _DetailsTopBar extends StatelessWidget {
  const _DetailsTopBar({required this.isFavorite, required this.onFavorite});
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _ProductDetailsScreenState._background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: _ProductDetailsScreenState._outlineVariant.withValues(
              alpha: 0.25,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _ProductDetailsScreenState._text,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              GeneratedLocalizations.of(context).productDetails,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProductDetailsScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded),
            color: _ProductDetailsScreenState._text,
          ),
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color: _ProductDetailsScreenState._text,
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatefulWidget {
  const _HeroImage({required this.product});

  final LendProduct product;

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = widget.product.images;
    final mediaCount = mediaItems.isEmpty ? 1 : mediaItems.length;
    final currentPage = (_currentIndex + 1).clamp(1, mediaCount);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ClipRect(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: mediaCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final media = mediaItems.isEmpty ? null : mediaItems[index];

                  return ProductMediaPreview(
                    product: widget.product,
                    media: media,
                    enableVideoPlayback: true,
                    autoPlayVideo:
                        media?.isVideo == true && index == _currentIndex,
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _ProductDetailsScreenState._background.withValues(
                      alpha: 0.90,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 15,
                          color: _ProductDetailsScreenState._muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentPage/$mediaCount',
                          style: const TextStyle(
                            color: _ProductDetailsScreenState._muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsInfoCard extends StatelessWidget {
  const _DetailsInfoCard({
    required this.product,
    required this.rentalMode,
    required this.mapStyle,
    required this.onPriceModeChanged,
  });

  final LendProduct product;
  final RentalMode rentalMode;
  final String? mapStyle;
  final ValueChanged<RentalMode> onPriceModeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleBlock(product: product),
            const SizedBox(height: 16),
            _StatusBadges(product: product),
            if (_isRealEstateProduct(product)) ...[
              const SizedBox(height: 18),
              _RoommateInviteCard(product: product),
            ],
            const SizedBox(height: 18),
            _ProductLocationMap(product: product, mapStyle: mapStyle),
            const SizedBox(height: 18),
            _PriceSwitcher(
              rentalMode: rentalMode,
              product: product,
              onChanged: onPriceModeChanged,
            ),
            const SizedBox(height: 24),
            _DescriptionSection(product: product),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: const TextStyle(
            color: _ProductDetailsScreenState._text,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
            const SizedBox(width: 4),
            Text(
              product.ratingLabel,
              style: const TextStyle(
                color: _ProductDetailsScreenState._text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              GeneratedLocalizations.of(context).verifiedItem,
              style: const TextStyle(
                color: _ProductDetailsScreenState._muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadges extends StatelessWidget {
  const _StatusBadges({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusBadge(
          icon: Icons.verified_user_rounded,
          label: GeneratedLocalizations.of(context).insuranceIncluded,
          color: _ProductDetailsScreenState._text,
        ),
        _StatusBadge(
          icon: Icons.check_circle_outline_rounded,
          label: GeneratedLocalizations.of(context).availableNow,
          color: Color(0xFF575750),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductLocationMap extends StatelessWidget {
  const _ProductLocationMap({required this.product, required this.mapStyle});

  final LendProduct product;
  final String? mapStyle;

  LatLng get _position {
    if (product.latitude != null && product.longitude != null) {
      return LatLng(product.latitude!, product.longitude!);
    }

    return _productCityCoordinates[_normalizeCity(product.city)] ??
        _ProductDetailsScreenState._bucharest;
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 156,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              style: mapStyle,
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: product.latitude == null ? 12 : 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('product-location'),
                  position: position,
                  onTap: () => _showDirectionsSheet(context, position),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onTap: (_) => _showDirectionsSheet(context, position),
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectionsSheet(BuildContext context, LatLng position) {
    final parentContext = context;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final strings = GeneratedLocalizations.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.openDirections,
                  style: const TextStyle(
                    color: _ProductDetailsScreenState._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.directionsBody,
                  style: const TextStyle(
                    color: _ProductDetailsScreenState._muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openGoogleMapsDirections(parentContext, position);
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(strings.openInGoogleMaps),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ProductDetailsScreenState._primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMapsDirections(
    BuildContext context,
    LatLng position,
  ) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${position.latitude},${position.longitude}',
      'travelmode': 'driving',
    });

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GeneratedLocalizations.of(context).googleMapsOpenError),
        ),
      );
    }
  }
}

class _PriceSwitcher extends StatelessWidget {
  const _PriceSwitcher({
    required this.rentalMode,
    required this.product,
    required this.onChanged,
  });

  final RentalMode rentalMode;
  final LendProduct product;
  final ValueChanged<RentalMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProductDetailsScreenState._surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_ProductDetailsScreenState._hasPriceForMode(
              product,
              RentalMode.hour,
            ))
              _SwitchButton(
                label: GeneratedLocalizations.of(context).hourly,
                selected: rentalMode == RentalMode.hour,
                onTap: () => onChanged(RentalMode.hour),
              ),
            if (_ProductDetailsScreenState._hasPriceForMode(
              product,
              RentalMode.day,
            ))
              _SwitchButton(
                label: GeneratedLocalizations.of(context).daily,
                selected: rentalMode == RentalMode.day,
                onTap: () => onChanged(RentalMode.day),
              ),
            if (_ProductDetailsScreenState._hasPriceForMode(
              product,
              RentalMode.month,
            ))
              _SwitchButton(
                label: GeneratedLocalizations.of(context).monthly,
                selected: rentalMode == RentalMode.month,
                onTap: () => onChanged(RentalMode.month),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _ProductDetailsScreenState._primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _ProductDetailsScreenState._muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(GeneratedLocalizations.of(context).description),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: const TextStyle(
            color: _ProductDetailsScreenState._muted,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.category_rounded,
        GeneratedLocalizations.of(context).category,
        product.category,
      ),
      (
        Icons.location_on_rounded,
        GeneratedLocalizations.of(context).location,
        product.address.isEmpty
            ? product.city
            : '${product.address}\n${product.city}',
      ),
      (
        Icons.account_balance_wallet_rounded,
        GeneratedLocalizations.of(context).deposit,
        '${product.deposit} RON',
      ),
      (
        Icons.schedule_rounded,
        GeneratedLocalizations.of(context).schedule,
        '${product.pickupTime} - ${product.returnTime}',
      ),
      (
        Icons.cleaning_services_rounded,
        GeneratedLocalizations.of(context).condition,
        GeneratedLocalizations.of(context).verified,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 124,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SpecCard(icon: item.$1, label: item.$2, value: item.$3);
      },
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: _ProductDetailsScreenState._text),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProductDetailsScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProductDetailsScreenState._text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GeneratedLocalizations.of(context).owner,
              style: const TextStyle(
                color: _ProductDetailsScreenState._muted,
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Stack(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.network(
                          product.ownerAvatarUrl ??
                              _ProductDetailsScreenState._ownerImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(color: Color(0xFFD3E3FF));
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _ProductDetailsScreenState._text,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.ownerName,
                        style: const TextStyle(
                          color: _ProductDetailsScreenState._text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _ProductDetailsScreenState._muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              GeneratedLocalizations.of(
                                context,
                              ).verifiedIdentity,
                              style: const TextStyle(
                                color: _ProductDetailsScreenState._muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: _ProductDetailsScreenState._outlineVariant),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OwnerStat(
                    value: '${product.ratingLabel}/5',
                    label: GeneratedLocalizations.of(context).rating,
                  ),
                ),
                const SizedBox(
                  height: 42,
                  child: VerticalDivider(
                    color: _ProductDetailsScreenState._outlineVariant,
                  ),
                ),
                Expanded(
                  child: _OwnerStat(
                    value: '${product.ownerRentalCount}',
                    label: GeneratedLocalizations.of(context).navRentals,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductChatScreen(
                        productId: product.id,
                        productTitle: product.title,
                        ownerName: product.ownerName,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ProductDetailsScreenState._text,
                  side: const BorderSide(
                    color: _ProductDetailsScreenState._text,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  GeneratedLocalizations.of(context).sendMessage,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectCard extends StatelessWidget {
  const _ProtectCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProductDetailsScreenState._secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.security_rounded,
              color: _ProductDetailsScreenState._secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lend Protect',
                    style: TextStyle(
                      color: _ProductDetailsScreenState._secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    GeneratedLocalizations.of(context).lendProtectBody,
                    style: const TextStyle(
                      color: _ProductDetailsScreenState._secondary,
                      fontSize: 12,
                      height: 1.35,
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.rentalMode, required this.product});

  final RentalMode rentalMode;
  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hourlyPrice = (product.pricePerDay / 8).round().clamp(
      1,
      product.pricePerDay,
    );
    final strings = GeneratedLocalizations.of(context);
    final price = switch (rentalMode) {
      RentalMode.hour => '$hourlyPrice RON',
      RentalMode.day => '${product.pricePerDay} RON',
      RentalMode.month => '${product.pricePerMonth ?? 0} RON',
    };
    final unit = switch (rentalMode) {
      RentalMode.hour => strings.perHourSuffix,
      RentalMode.day => strings.perDaySuffix,
      RentalMode.month => strings.pricePerMonthShort,
    };

    return Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, bottomPadding + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _ProductDetailsScreenState._outlineVariant.withValues(
              alpha: 0.30,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text.rich(
              TextSpan(
                text: price,
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      color: _ProductDetailsScreenState._muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                color: _ProductDetailsScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RentalPeriodScreen(
                        product: product,
                        rentalMode: rentalMode,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _ProductDetailsScreenState._primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: _ProductDetailsScreenState._primary.withValues(
                    alpha: 0.16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final strings = GeneratedLocalizations.of(context);
                    final label = constraints.maxWidth < 150
                        ? strings.rent
                        : strings.rentNow;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _normalizeCity(String city) {
  return city
      .trim()
      .toLowerCase()
      .replaceAll('\\u0103', 'a')
      .replaceAll('\\u00e2', 'a')
      .replaceAll('\\u00ee', 'i')
      .replaceAll('\\u0219', 's')
      .replaceAll('\\u015f', 's')
      .replaceAll('\\u021b', 't')
      .replaceAll('\\u0163', 't');
}

bool _isRealEstateProduct(LendProduct product) {
  return _normalizeCategory(product.categorySlug) == 'imobiliare';
}

String _normalizeCategory(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ă', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ș', 's')
      .replaceAll('ş', 's')
      .replaceAll('ț', 't')
      .replaceAll('ţ', 't');
}

const _productCityCoordinates = <String, LatLng>{
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ProductDetailsScreenState._text,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _OwnerStat extends StatelessWidget {
  const _OwnerStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _ProductDetailsScreenState._text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _ProductDetailsScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ],
);
