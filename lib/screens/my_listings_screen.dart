import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/storage_api.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import '../widgets/product_media_preview.dart';
import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key, this.showChrome = true, this.onNavigate});

  final bool showChrome;
  final ValueChanged<int>? onNavigate;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  static const _primary = Color(0xFF30578F);
  static const _primaryContainer = Color(0xFF4A70A9);
  static const _background = Color(0xFFEFECE3);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outlineVariant = Color(0xFFC3C6D1);
  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAxU9zb3XzQztSdX10Pwsi94SR-JS7BeYbBv0zblLU2pbPw0NPogsqzSm2F5wbCc9DajEx_XEfHtHT0Ht07MAg4WOBvmk86NmGa_MPsfbBcEQQ5jSz2fokajuOWGZ7EovVUX_CP1JKPZavBkNo2W-rKqh442JG1-cWnVAr9crTtSjAFQiQRn99_ZYYKd2xlqTXx8SX1MuP-Ymj6MpmI0s9ZO0HNZcs1FN9DDoRw8-h0tcPVtj9BoHUUxk4eeimvDN9aqQA8Q2aTu6M';

  final _productsApi = ProductsApi();
  late Future<List<LendProduct>> _myListings;

  @override
  void initState() {
    super.initState();
    _myListings = _loadMyListings();
  }

  Future<List<LendProduct>> _loadMyListings() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      throw ProductsApiException('Trebuie sa fii autentificat.');
    }

    return _productsApi.findMine(token);
  }

  void _reloadListings() {
    setState(() {
      _myListings = _loadMyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        CustomScrollView(
          slivers: [
            if (widget.showChrome)
              const SliverToBoxAdapter(
                child: LendTopBar(
                  title: 'Anunturile Mele',
                  avatarUrl: _MyListingsScreenState._avatarUrl,
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 114)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.showChrome ? 32 : 0,
                20,
                widget.showChrome ? 168 : 6,
              ),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder<List<LendProduct>>(
                  future: _myListings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _ListingsLoading();
                    }

                    if (snapshot.hasError) {
                      return _ListingsError(onRetry: _reloadListings);
                    }

                    final items = snapshot.data ?? const [];

                    return Column(
                      children: [
                        _StatsGrid(items: items),
                        const SizedBox(height: 48),
                        if (items.isEmpty)
                          const _EmptyListings()
                        else
                          _ListingsGrid(items: items),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: widget.showChrome ? 116 : 24,
          child: _AddListingButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddListingScreen(),
                ),
              );
            },
          ),
        ),
        if (widget.showChrome)
          Align(
            alignment: Alignment.bottomCenter,
            child: LendBottomNavigation(
              currentIndex: 1,
              onSelected: _handleNavigation,
            ),
          ),
      ],
    );

    if (!widget.showChrome) {
      return content;
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(bottom: false, child: content),
    );
  }

  void _handleNavigation(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ExploreScreen()),
      );
    }
    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RentalsScreen()),
      );
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      );
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<LendProduct> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stats = _stats(context);
        final crossAxisCount = constraints.maxWidth >= 760 ? 4 : 2;

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 108,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _StatCard(label: stat.$1, value: stat.$2, color: stat.$3);
          },
        );
      },
    );
  }

  List<(String, String, Color)> _stats(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final activeCount = items.where((item) => item.isAvailable).length;
    final rentedCount = items.length - activeCount;
    final income = items.fold<int>(
      0,
      (sum, item) => sum + (item.isAvailable ? 0 : item.pricePerDay),
    );
    final rating = items.isEmpty
        ? '-'
        : (items.fold<double>(0, (sum, item) => sum + item.rating) /
                  items.length)
              .toStringAsFixed(1);

    return [
      (
        strings.choose('Active', 'Active'),
        '$activeCount',
        _MyListingsScreenState._primary,
      ),
      (
        strings.choose('Inchiriate', 'Rented'),
        '$rentedCount',
        const Color(0xFF446085),
      ),
      (
        strings.choose('Venit total', 'Total income'),
        '$income lei',
        _MyListingsScreenState._primary,
      ),
      (
        strings.choose('Recenzii', 'Reviews'),
        rating,
        _MyListingsScreenState._primary,
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MyListingsScreenState._muted,
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (label ==
                    AppLocalizations.of(
                      context,
                    ).choose('Recenzii', 'Reviews')) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star_rounded,
                    color: _MyListingsScreenState._primary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingsGrid extends StatelessWidget {
  const _ListingsGrid({required this.items});

  final List<LendProduct> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 430,
          ),
          itemBuilder: (context, index) {
            return _ListingCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item});

  final LendProduct item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 224,
          decoration: _cardDecoration,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductMediaPreview(product: item),
              Positioned(
                top: 16,
                left: 16,
                child: _StatusPill(active: item.isAvailable),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _MyListingsScreenState._text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.pricePerDayLabel,
                      style: const TextStyle(
                        color: _MyListingsScreenState._primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _MyListingsScreenState._muted,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AddListingScreen(
                                  initialData: ListingFormData(
                                    productId: item.id,
                                    title: item.title,
                                    description: item.description,
                                    pricePerDay: item.pricePerDay.toString(),
                                    category: item.categorySlug,
                                    categoryLabel: item.category,
                                    deposit: item.deposit.toString(),
                                    city: item.city,
                                    imageUrl: item.imageUrl,
                                    media: item.images
                                        .map(
                                          (media) => UploadedMedia(
                                            key: media.key,
                                            url: media.url,
                                            alt: media.alt,
                                            contentType: media.contentType,
                                            type: media.type,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _MyListingsScreenState._primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).choose('Editeaza', 'Edit'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: _MyListingsScreenState._muted,
                          side: const BorderSide(
                            color: _MyListingsScreenState._outlineVariant,
                          ),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(Icons.more_vert_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFD3E3FF);
    final foreground = active
        ? const Color(0xFF15803D)
        : const Color(0xFF2B486C);
    final strings = AppLocalizations.of(context);
    final label = active
        ? strings.choose('Activ', 'Active')
        : strings.choose('Inchiriat', 'Rented');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
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

class _ListingsLoading extends StatelessWidget {
  const _ListingsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(
        child: CircularProgressIndicator(
          color: _MyListingsScreenState._primary,
        ),
      ),
    );
  }
}

class _ListingsError extends StatelessWidget {
  const _ListingsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return _MessagePanel(
      icon: Icons.cloud_off_rounded,
      title: strings.choose(
        'Nu am putut incarca anunturile',
        'Could not load listings',
      ),
      body: strings.choose(
        'Verifica daca backendul este pornit si incearca din nou.',
        'Check that the backend is running and try again.',
      ),
      actionLabel: strings.retry,
      onAction: onRetry,
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return _MessagePanel(
      icon: Icons.inventory_2_outlined,
      title: strings.choose('Nu ai anunturi inca', 'No listings yet'),
      body: strings.choose(
        'Anunturile create de contul tau vor aparea aici direct din baza de date.',
        'Listings created by your account will appear here directly from the database.',
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: _MyListingsScreenState._primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _MyListingsScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _MyListingsScreenState._muted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: _MyListingsScreenState._primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddListingButton extends StatelessWidget {
  const _AddListingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: _MyListingsScreenState._primaryContainer,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        AppLocalizations.of(context).choose('Adauga anunt', 'Add listing'),
        style: const TextStyle(fontWeight: FontWeight.w800),
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
