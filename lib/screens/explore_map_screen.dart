import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/products_api.dart';
import '../widgets/product_media_preview.dart';
import 'product_details_screen.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key, required this.products});

  final List<LendProduct> products;

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _bucharest = LatLng(44.4268, 26.1025);

  GoogleMapController? _mapController;
  late final List<_ProductMarker> _productMarkers = _buildProductMarkers();

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final markers = _productMarkers
        .map(
          (item) => Marker(
            markerId: MarkerId(item.product.id),
            position: item.position,
            infoWindow: InfoWindow(
              title: item.product.title,
              snippet:
                  '${item.product.city} - ${item.product.pricePerDayLabel}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            onTap: () => _focusProduct(item),
          ),
        )
        .toSet();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialTarget,
                zoom: widget.products.isEmpty ? 6 : 11.5,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMarkers();
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 12,
              child: _MapTopBar(
                title: strings.map,
                subtitle: strings.choose(
                  '${widget.products.length} produse disponibile',
                  '${widget.products.length} available items',
                ),
              ),
            ),
            if (widget.products.isEmpty)
              Center(
                child: _EmptyMapMessage(
                  text: strings.choose(
                    'Nu exista produse de afisat pe harta.',
                    'There are no items to show on the map.',
                  ),
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding + 16,
                child: SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _productMarkers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _productMarkers[index];
                      return _MapProductCard(
                        product: item.product,
                        onTap: () => _focusProduct(item),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProductDetailsScreen(product: item.product),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LatLng get _initialTarget {
    if (_productMarkers.isEmpty) {
      return _bucharest;
    }

    return _productMarkers.first.position;
  }

  List<_ProductMarker> _buildProductMarkers() {
    final cityCounts = <String, int>{};

    return widget.products.map((product) {
      final normalizedCity = _normalizeCity(product.city);
      final cityIndex = cityCounts.update(
        normalizedCity,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final base = _cityCoordinates[normalizedCity] ?? _bucharest;
      final offset = _offsetFor(product.id, cityIndex);

      return _ProductMarker(
        product: product,
        position: LatLng(
          base.latitude + offset.latitude,
          base.longitude + offset.longitude,
        ),
      );
    }).toList();
  }

  Future<void> _focusProduct(_ProductMarker item) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: item.position, zoom: 13.5),
      ),
    );
  }

  Future<void> _fitMarkers() async {
    if (_productMarkers.length < 2) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }

    final bounds = _boundsFor(_productMarkers.map((item) => item.position));
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 72),
    );
  }

  LatLngBounds _boundsFor(Iterable<LatLng> points) {
    final iterator = points.iterator..moveNext();
    var minLat = iterator.current.latitude;
    var maxLat = iterator.current.latitude;
    var minLng = iterator.current.longitude;
    var maxLng = iterator.current.longitude;

    while (iterator.moveNext()) {
      final point = iterator.current;
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLng _offsetFor(String id, int cityIndex) {
    final seed = id.codeUnits.fold<int>(
      cityIndex + 1,
      (sum, item) => sum + item,
    );
    final latDirection = seed.isEven ? 1 : -1;
    final lngDirection = seed % 3 == 0 ? 1 : -1;
    final spread = 0.008 + (cityIndex % 5) * 0.004;

    return LatLng(spread * latDirection, spread * lngDirection);
  }

  String _normalizeCity(String city) {
    return city
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
}

class _ProductMarker {
  const _ProductMarker({required this.product, required this.position});

  final LendProduct product;
  final LatLng position;
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: _ExploreMapScreenState._text,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ExploreMapScreenState._text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ExploreMapScreenState._muted,
                      fontSize: 12,
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

class _MapProductCard extends StatelessWidget {
  const _MapProductCard({
    required this.product,
    required this.onTap,
    required this.onOpen,
  });

  final LendProduct product;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 10,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 292,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 86,
                    height: 112,
                    child: ProductMediaPreview(product: product),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ExploreMapScreenState._text,
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ExploreMapScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.pricePerDayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ExploreMapScreenState._primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onOpen,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            color: _ExploreMapScreenState._text,
                            tooltip: AppLocalizations.of(
                              context,
                            ).choose('Deschide produsul', 'Open item'),
                          ),
                        ],
                      ),
                    ],
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

class _EmptyMapMessage extends StatelessWidget {
  const _EmptyMapMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ExploreMapScreenState._muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

const _cityCoordinates = <String, LatLng>{
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
