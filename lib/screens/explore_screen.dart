import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/categories_api.dart';
import '../services/products_api.dart';
import '../widgets/product_media_preview.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import 'add_listing_screen.dart';
import 'my_listings_screen.dart';
import 'product_details_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.showChrome = true, this.onNavigate});

  final bool showChrome;
  final ValueChanged<int>? onNavigate;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);

  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAjckt39yhGH_YNEWoUmbXYYMQMctYpenv4ao2wyvCqeIUeKvR_KLOZ2ICz2VXNFVBoWxN3Tk3Y95Eg_PbtaBhRH8vX_vZ4HtStk-hQiK-xTgYACenslrsS991egJa7dNNA21VSeZYxwr6eC9bd1mcpjvb13V7JeJ9DH2YWlHFFMYoGLdsewDMPaYY36MgZ-5ctsmYioywxLYl5q_-pxR5zE3v4A_fnVaDTGQCU2CLBpYxMQ9xhXdfKEtFQuchnrja44C5pVFpxxII';

  late Future<_ExploreData> _exploreFuture;
  int _selectedCategoryIndex = 0;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _exploreFuture = _loadExploreData();
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      color: _text,
      onRefresh: () async {
        setState(() {
          _exploreFuture = _loadExploreData();
        });
        await _exploreFuture;
      },
      child: CustomScrollView(
        slivers: [
          if (widget.showChrome)
            SliverToBoxAdapter(
              child: LendTopBar(
                title: AppLocalizations.of(context).appName,
                avatarUrl: _ExploreScreenState._avatarUrl,
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 102)),
          FutureBuilder<_ExploreData>(
            future: _exploreFuture,
            builder: (context, snapshot) {
              final products = snapshot.data?.products ?? const <LendProduct>[];
              final categories = _categoriesFor(
                snapshot.data?.categories ?? const <LendCategory>[],
              );
              final selectedIndex = _selectedCategoryIndex.clamp(
                0,
                categories.length - 1,
              );
              final visibleProducts = _filterProducts(
                products,
                categories[selectedIndex],
              );

              return SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _ExploreHeader(
                      categories: categories,
                      selectedIndex: selectedIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _ProductsLoadingState()
                  else if (snapshot.hasError)
                    _ProductsErrorState(onRetry: _reloadProducts)
                  else if (visibleProducts.isEmpty)
                    const _EmptyProductsState()
                  else ...[
                    _RecommendedSection(
                      products: visibleProducts.take(6).toList(),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                      child: _NearbyGrid(products: visibleProducts),
                    ),
                  ],
                ]),
              );
            },
          ),
        ],
      ),
    );

    if (!widget.showChrome) {
      return content;
    }

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
                content,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LendBottomNavigation(
                    currentIndex: _selectedNavIndex,
                    onSelected: _handleNavigation,
                    onAddListing: _openAddListing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MyListingsScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RentalsScreen()),
      );
      return;
    }

    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _openAddListing() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddListingScreen()));
  }

  void _reloadProducts() {
    setState(() {
      _exploreFuture = _loadExploreData();
    });
  }

  Future<_ExploreData> _loadExploreData() async {
    final productsFuture = ProductsApi().findAll();
    final categoriesFuture = CategoriesApi().findAll();

    return _ExploreData(
      products: await productsFuture,
      categories: await categoriesFuture,
    );
  }

  List<_CategoryFilter> _categoriesFor(List<LendCategory> categories) {
    return [
      _CategoryFilter(label: AppLocalizations.of(context).all, slug: null),
      ...categories.map(
        (category) =>
            _CategoryFilter(label: category.name, slug: category.slug),
      ),
    ];
  }

  List<LendProduct> _filterProducts(
    List<LendProduct> products,
    _CategoryFilter category,
  ) {
    if (category.slug == null) {
      return products;
    }

    return products
        .where((product) => product.categorySlug == category.slug)
        .toList();
  }
}

class _ExploreData {
  const _ExploreData({required this.products, required this.categories});

  final List<LendProduct> products;
  final List<LendCategory> categories;
}

class _CategoryFilter {
  const _CategoryFilter({required this.label, required this.slug});

  final String label;
  final String? slug;
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_CategoryFilter> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.exploreObjects,
                style: const TextStyle(
                  color: _ExploreScreenState._text,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Material(
              color: _ExploreScreenState._text,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: Colors.black26,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final selected = index == selectedIndex;

              return ChoiceChip(
                label: Text(categories[index].label),
                selected: selected,
                onSelected: (_) => onSelected(index),
                showCheckmark: false,
                selectedColor: _ExploreScreenState._primary,
                backgroundColor: const Color(
                  0xFF446085,
                ).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _ExploreScreenState._text,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.products});

  final List<LendProduct> products;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeader(
            title: strings.recommended,
            action: strings.seeAll,
            onAction: () {},
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 430,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              return _RecommendedCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _NearbyGrid extends StatelessWidget {
  const _NearbyGrid({required this.products});

  final List<LendProduct> products;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        _SectionHeader(
          title: strings.nearYou,
          action: strings.map,
          onAction: () {},
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 640
                ? 3
                : 2;

            return GridView.builder(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 230,
              ),
              itemBuilder: (context, index) {
                return _NearbyCard(product: products[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ExploreScreenState._text,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _ExploreScreenState._text,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openProductDetails(context, product),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 306,
              decoration: _cardDecoration,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductMediaPreview(product: product),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: _Badge(text: 'DB'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: _cardDecoration,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ExploreScreenState._text,
                                fontSize: 18,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriceText(price: product.priceLabel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: _ExploreScreenState._muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${product.city} • ${product.category}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ExploreScreenState._muted,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openProductDetails(context, product),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: _cardDecoration,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductMediaPreview(product: product),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _DistanceBadge(text: product.city),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ExploreScreenState._text,
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
                          style: const TextStyle(
                            color: _ExploreScreenState._text,
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
                          color: _ExploreScreenState._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openProductDetails(BuildContext context, LendProduct product) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailsScreen(product: product),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: _ExploreScreenState._text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ExploreScreenState._text,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Text.rich(
      TextSpan(
        text: price,
        children: [
          TextSpan(
            text: strings.dayShort,
            style: const TextStyle(
              color: _ExploreScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      style: const TextStyle(
        color: _ExploreScreenState._text,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProductsLoadingState extends StatelessWidget {
  const _ProductsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 40, 20, 116),
      child: Center(
        child: CircularProgressIndicator(color: _ExploreScreenState._text),
      ),
    );
  }
}

class _ProductsErrorState extends StatelessWidget {
  const _ProductsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 116),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).productsLoadError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ExploreScreenState._muted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _ExploreScreenState._primary,
            ),
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 116),
      child: Text(
        AppLocalizations.of(context).emptyProducts,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ExploreScreenState._muted,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);
