import 'package:flutter/material.dart';

import '../l10n/generated_localizations.dart';
import '../services/products_api.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_back_top_bar.dart';
import '../widgets/product_media_preview.dart';
import 'product_details_screen.dart';

class OwnerListingsScreen extends StatefulWidget {
  const OwnerListingsScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  static const _background = Color(0xFFF9F9F9);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);

  late Future<List<LendProduct>> _listings;

  @override
  void initState() {
    super.initState();
    _listings = _loadListings();
  }

  void _reload() {
    setState(() {
      _listings = _loadListings();
    });
  }

  Future<List<LendProduct>> _loadListings() async {
    final products = await ProductsApi().findAll();
    final ownerId = widget.product.ownerId;
    // Older seeded products do not have an owner ID.
    return products.where((product) {
      if (ownerId != null) return product.ownerId == ownerId;
      return product.ownerId == null &&
          product.ownerName == widget.product.ownerName;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';

    return LendScreenFrame(
      backgroundColor: _background,
      child: Scaffold(
        backgroundColor: _background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(LendBackTopBar.height),
          child: LendBackTopBar(
            title: english ? 'Owner profile' : 'Profil proprietar',
          ),
        ),
        body: FutureBuilder<List<LendProduct>>(
          future: _listings,
          builder: (context, snapshot) {
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _listings;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  _OwnerHeader(product: widget.product),
                  const SizedBox(height: 28),
                  Text(
                    english ? 'Listings' : 'Anunțuri',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError)
                    _MessageCard(
                      message: strings.couldNotLoadListings,
                      action: strings.retry,
                      onPressed: _reload,
                    )
                  else if ((snapshot.data ?? []).isEmpty)
                    _MessageCard(
                      message: english
                          ? 'This owner has no listings yet.'
                          : 'Acest proprietar nu are anunțuri încă.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 640
                            ? 3
                            : 2;
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 230,
                              ),
                          itemBuilder: (context, index) =>
                              _ListingCard(product: snapshot.data![index]),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);
    final avatarUrl = product.ownerAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _ownerCardShadows,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFD3E3FF),
            foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
            child: const Icon(Icons.person_rounded, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.ownerName.isEmpty
                      ? strings.ownerDefaultName
                      : product.ownerName,
                  style: const TextStyle(
                    color: _OwnerListingsScreenState._text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        strings.verifiedIdentity,
                        style: const TextStyle(
                          color: _OwnerListingsScreenState._muted,
                          fontSize: 12,
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
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: _listingCardDecoration,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductMediaPreview(product: product),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          product.city.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _OwnerListingsScreenState._text,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _listingCardDecoration,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _OwnerListingsScreenState._text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.pricePerDayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _OwnerListingsScreenState._text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.ratingLabel,
                      style: const TextStyle(
                        color: _OwnerListingsScreenState._muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _listingCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: _ownerCardShadows,
);

const _ownerCardShadows = <BoxShadow>[
  BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
];

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.action, this.onPressed});

  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onPressed != null)
            TextButton(onPressed: onPressed, child: Text(action ?? 'Retry')),
        ],
      ),
    );
  }
}
