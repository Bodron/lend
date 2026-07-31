import 'package:flutter/material.dart';

import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'my_listings_screen.dart';
import 'profile_screen.dart';
import 'return_qr_screen.dart';
import 'return_scan_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import '../widgets/product_media_preview.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key, this.showChrome = true, this.onNavigate});

  final bool showChrome;
  final ValueChanged<int>? onNavigate;

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _error = Color(0xFFBA1A1A);
  static const _secondary = Color(0xFF446085);
  static const _secondaryContainer = Color(0xFFB7D3FE);

  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAnLFvkG7ua6sGaejlIx0m1PZMxtqm6qBOtKTKoAtpLGpxra9RYBL_Sh3BY_wyZaDUmQf250BMCPmFnVKbyOE2DNXNwkBCaOEd8MOZt468-N9dMGrZhXn1unw24d2b3AjNO6mU1qc0gFoGPzeOoQpAASY3IsJwbXq4GXC6TnoBRgEYW39NJUjL_m9wpT7NPj1nm6nTzRghMMl9uKvooV2P5Fthp5BuU-G3b0u2jVTO1zM8kkk6SReSl4Y0QceQTdFqFRKQfnAh9l88';

  _RentalPerspective _perspective = _RentalPerspective.renting;
  bool _showHistory = false;
  final _rentalOrdersApi = RentalOrdersApi();
  late Future<_RentalsData> _orders = _loadOrders();

  Future<_RentalsData> _loadOrders() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      throw RentalOrdersApiException('Trebuie sa fii autentificat.');
    }

    final results = await Future.wait([
      _rentalOrdersApi.findMine(token),
      _rentalOrdersApi.findOwned(token),
    ]);

    return _RentalsData(renting: results[0], lending: results[1]);
  }

  void _reloadOrders() {
    setState(() {
      _orders = _loadOrders();
    });
  }

  static bool _isHistoryOrder(RentalOrder order) {
    return order.status == 'completed' ||
        order.status == 'cancelled' ||
        order.status == 'rejected';
  }

  static _RentalItem _rentalItemFromOrder(
    RentalOrder order,
    _RentalPerspective perspective,
  ) {
    final expiring = order.endDate != null && _isToday(order.endDate!);
    final ownerName = order.productOwnerName.isEmpty
        ? 'Proprietar'
        : order.productOwnerName;
    final renterName = order.renterName.isEmpty ? 'Chirias' : order.renterName;

    return _RentalItem(
      id: order.id,
      title: order.productTitle.isEmpty
          ? 'Produs inchiriat'
          : order.productTitle,
      dateText: order.endDate == null
          ? 'Comanda trimisa'
          : 'Pana la ${_formatShortDate(order.endDate!)}',
      imageUrl: order.productImageUrl,
      imageContentType: order.productImageContentType,
      imageType: order.productImageType,
      detailText: perspective == _RentalPerspective.renting
          ? 'De la $ownerName'
          : 'Chirias: $renterName',
      status: expiring ? _RentalStatus.expiring : _RentalStatus.active,
    );
  }

  static _RentalHistoryItem _historyItemFromOrder(RentalOrder order) {
    final start = order.startDate;
    final end = order.endDate;

    return _RentalHistoryItem(
      title: order.productTitle.isEmpty
          ? 'Produs inchiriat'
          : order.productTitle,
      dateText: start == null || end == null
          ? 'Inchiriere finalizata'
          : 'Inchiriat: ${_formatShortDate(start)} - ${_formatShortDate(end)}',
      imageUrl: order.productImageUrl,
      imageContentType: order.productImageContentType,
      imageType: order.productImageType,
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String _formatShortDate(DateTime date) {
    const months = [
      'Ian',
      'Feb',
      'Mar',
      'Apr',
      'Mai',
      'Iun',
      'Iul',
      'Aug',
      'Sep',
      'Oct',
      'Noi',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                if (widget.showChrome)
                  const SliverToBoxAdapter(
                    child: LendTopBar(
                      title: 'Închirierile Mele',
                      avatarUrl: _RentalsScreenState._avatarUrl,
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    widget.showChrome ? 28 : 0,
                    20,
                    widget.showChrome ? 128 : 6,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PerspectiveTabs(
                        selected: _perspective,
                        onChanged: (value) {
                          setState(() {
                            _perspective = value;
                            _showHistory = false;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _RentalTabs(
                        showHistory: _showHistory,
                        onChanged: (value) {
                          setState(() {
                            _showHistory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<_RentalsData>(
                        future: _orders,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const SizedBox(
                              height: 260,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _RentalsScreenState._text,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return _RentalsMessage(
                              icon: Icons.cloud_off_rounded,
                              title: AppLocalizations.of(context).choose(
                                'Nu am putut incarca inchirierile',
                                'Could not load rentals',
                              ),
                              body: AppLocalizations.of(context).choose(
                                'Verifica backendul si incearca din nou.',
                                'Check the backend and try again.',
                              ),
                              actionLabel: AppLocalizations.of(context).retry,
                              onAction: _reloadOrders,
                            );
                          }

                          final data = snapshot.data!;
                          final orders = _perspective == _RentalPerspective.renting
                              ? data.renting
                              : data.lending;
                          final activeItems = orders
                              .where((order) => !_isHistoryOrder(order))
                              .map(
                                (order) =>
                                    _rentalItemFromOrder(order, _perspective),
                              )
                              .toList();
                          final historyItems = orders
                              .where(_isHistoryOrder)
                              .map(_historyItemFromOrder)
                              .toList();

                          if (!_showHistory && activeItems.isEmpty) {
                            return _RentalsMessage(
                              icon: Icons.handshake_outlined,
                              title: AppLocalizations.of(context).choose(
                                'Nu ai inchirieri active',
                                'No active rentals',
                              ),
                              body: AppLocalizations.of(context).choose(
                                _perspective == _RentalPerspective.renting
                                    ? 'Comenzile trimise pentru inchiriere vor aparea aici.'
                                    : 'Comenzile primite pe produsele tale vor aparea aici.',
                                _perspective == _RentalPerspective.renting
                                    ? 'Submitted rental orders will appear here.'
                                    : 'Orders received for your items will appear here.',
                              ),
                            );
                          }

                          if (_showHistory && historyItems.isEmpty) {
                            return _RentalsMessage(
                              icon: Icons.history_rounded,
                              title: AppLocalizations.of(
                                context,
                              ).choose('Nu ai istoric inca', 'No history yet'),
                              body: AppLocalizations.of(context).choose(
                                'Inchirierile finalizate vor aparea aici.',
                                'Completed rentals will appear here.',
                              ),
                            );
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _showHistory
                                ? _HistoryRentalsGrid(
                                    key: const ValueKey('history-rentals'),
                                    items: historyItems,
                                  )
                                : _ActiveRentalsGrid(
                                    key: const ValueKey('active-rentals'),
                                    items: activeItems,
                                    perspective: _perspective,
                                    onScanReturn: _openReturnScanner,
                                  ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            if (widget.showChrome)
              Align(
                alignment: Alignment.bottomCenter,
                child: LendBottomNavigation(
                  currentIndex: 2,
                  onSelected: _handleNavigation,
                  onAddListing: _openAddListing,
                ),
              ),
          ],
        ),
      ),
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
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MyListingsScreen()),
      );
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      );
    }
  }

  void _openAddListing() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddListingScreen()));
  }

  Future<void> _openReturnScanner() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ReturnScanScreen()),
    );

    if (completed == true && mounted) {
      _reloadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).choose('Retur confirmat.', 'Return confirmed.'),
          ),
        ),
      );
    }
  }
}

class _RentalsMessage extends StatelessWidget {
  const _RentalsMessage({
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
      decoration: _rentalCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: _RentalsScreenState._text, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _RentalsScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _RentalsScreenState._muted,
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
                  backgroundColor: _RentalsScreenState._primary,
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

class _PerspectiveTabs extends StatelessWidget {
  const _PerspectiveTabs({
    required this.selected,
    required this.onChanged,
  });

  final _RentalPerspective selected;
  final ValueChanged<_RentalPerspective> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC3C6D1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _PerspectiveTab(
                icon: Icons.shopping_bag_outlined,
                label: strings.choose('Eu inchiriez', 'I rent'),
                selected: selected == _RentalPerspective.renting,
                onTap: () => onChanged(_RentalPerspective.renting),
              ),
            ),
            Expanded(
              child: _PerspectiveTab(
                icon: Icons.storefront_rounded,
                label: strings.choose('De la mine', 'From me'),
                selected: selected == _RentalPerspective.lending,
                onTap: () => onChanged(_RentalPerspective.lending),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerspectiveTab extends StatelessWidget {
  const _PerspectiveTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _RentalsScreenState._text : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : _RentalsScreenState._muted,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _RentalsScreenState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalTabs extends StatelessWidget {
  const _RentalTabs({required this.showHistory, required this.onChanged});

  final bool showHistory;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDED9C8))),
      ),
      child: Row(
        children: [
          _RentalTab(
            label: strings.choose('Active', 'Active'),
            selected: !showHistory,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 32),
          _RentalTab(
            label: strings.choose('Istoric', 'History'),
            selected: showHistory,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _RentalTab extends StatelessWidget {
  const _RentalTab({
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? _RentalsScreenState._text
                    : _RentalsScreenState._muted,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: selected
                    ? _RentalsScreenState._primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRentalsGrid extends StatelessWidget {
  const _ActiveRentalsGrid({
    super.key,
    required this.items,
    required this.perspective,
    required this.onScanReturn,
  });

  final List<_RentalItem> items;
  final _RentalPerspective perspective;
  final VoidCallback onScanReturn;

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
            mainAxisExtent: 390,
          ),
          itemBuilder: (context, index) {
            return _ActiveRentalCard(
              item: items[index],
              perspective: perspective,
              onScanReturn: onScanReturn,
            );
          },
        );
      },
    );
  }
}

class _ActiveRentalCard extends StatelessWidget {
  const _ActiveRentalCard({
    required this.item,
    required this.perspective,
    required this.onScanReturn,
  });

  final _RentalItem item;
  final _RentalPerspective perspective;
  final VoidCallback onScanReturn;

  @override
  Widget build(BuildContext context) {
    final expiring = item.status == _RentalStatus.expiring;

    return DecoratedBox(
      decoration: _rentalCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 224,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RentalMediaPreview(
                    title: item.title,
                    imageUrl: item.imageUrl,
                    imageContentType: item.imageContentType,
                    imageType: item.imageType,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _StatusBadge(
                      text: expiring ? 'Expiră azi' : 'În Curs',
                      color: expiring
                          ? _RentalsScreenState._error
                          : _RentalsScreenState._primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _RentalsScreenState._text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          perspective == _RentalPerspective.renting
                              ? Icons.storefront_rounded
                              : Icons.person_outline_rounded,
                          color: _RentalsScreenState._muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.detailText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _RentalsScreenState._muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          expiring
                              ? Icons.schedule_rounded
                              : Icons.calendar_today_rounded,
                          color: expiring
                              ? _RentalsScreenState._error
                              : _RentalsScreenState._muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: expiring
                                  ? _RentalsScreenState._error
                                  : _RentalsScreenState._muted,
                              fontSize: 14,
                              fontWeight: expiring
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () {
                          if (perspective == _RentalPerspective.lending) {
                            onScanReturn();
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReturnQrScreen(
                                itemTitle: item.title,
                                itemImageUrl: item.imageUrl,
                                returnCode: 'borrowit:return:${item.id}',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _RentalsScreenState._primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).choose(
                            perspective == _RentalPerspective.renting
                                ? 'Finalizeaza returul'
                                : 'Scaneaza cod retur',
                            perspective == _RentalPerspective.renting
                                ? 'Complete return'
                                : 'Scan return code',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRentalsGrid extends StatelessWidget {
  const _HistoryRentalsGrid({super.key, required this.items});

  final List<_RentalHistoryItem> items;

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
            mainAxisExtent: 314,
          ),
          itemBuilder: (context, index) {
            return _HistoryRentalCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _RentalMediaPreview extends StatelessWidget {
  const _RentalMediaPreview({
    required this.title,
    required this.imageUrl,
    required this.imageContentType,
    required this.imageType,
  });

  final String title;
  final String imageUrl;
  final String imageContentType;
  final String imageType;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ColoredBox(color: Color(0xFFE2E2E2));
    }

    return ProductMediaPreview(
      product: _emptyProduct,
      media: LendProductImage(
        url: imageUrl,
        key: '',
        alt: title,
        contentType: imageContentType,
        type: imageType.isEmpty ? 'image' : imageType,
      ),
    );
  }
}

class _HistoryRentalCard extends StatelessWidget {
  const _HistoryRentalCard({required this.item});

  final _RentalHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: DecoratedBox(
        decoration: _rentalCardDecoration.copyWith(
          color: Colors.white.withValues(alpha: 0.60),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 192,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFE2E2E2),
                    BlendMode.saturation,
                  ),
                  child: _RentalMediaPreview(
                    title: item.title,
                    imageUrl: item.imageUrl,
                    imageContentType: item.imageContentType,
                    imageType: item.imageType,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RentalsScreenState._muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _RentalsScreenState._muted.withValues(
                          alpha: 0.70,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: _RentalsScreenState._text,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).choose(
                            'Returnat cu succes',
                            'Returned successfully',
                          ),
                          style: const TextStyle(
                            color: _RentalsScreenState._text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayText = _displayText(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          displayText.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _displayText(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final normalized = text.toLowerCase();

    if (normalized.contains('azi') || normalized.contains('today')) {
      return strings.choose('Expira azi', 'Expires today');
    }

    if (normalized.contains('curs') || normalized.contains('progress')) {
      return strings.choose('In curs', 'In progress');
    }

    return text;
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _RentalsScreenState._secondaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: _RentalsScreenState._secondary,
              size: 14,
            ),
            const SizedBox(width: 3),
            Text(
              AppLocalizations.of(context).choose('Verificat', 'Verified'),
              style: const TextStyle(
                color: _RentalsScreenState._secondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalItem {
  const _RentalItem({
    required this.id,
    required this.title,
    required this.dateText,
    required this.imageUrl,
    required this.imageContentType,
    required this.imageType,
    required this.detailText,
    required this.status,
  });

  final String id;
  final String title;
  final String dateText;
  final String imageUrl;
  final String imageContentType;
  final String imageType;
  final String detailText;
  final _RentalStatus status;
}

class _RentalHistoryItem {
  const _RentalHistoryItem({
    required this.title,
    required this.dateText,
    required this.imageUrl,
    required this.imageContentType,
    required this.imageType,
  });

  final String title;
  final String dateText;
  final String imageUrl;
  final String imageContentType;
  final String imageType;
}

enum _RentalStatus { active, expiring }

enum _RentalPerspective { renting, lending }

class _RentalsData {
  const _RentalsData({required this.renting, required this.lending});

  final List<RentalOrder> renting;
  final List<RentalOrder> lending;
}

const _emptyProduct = LendProduct(
  id: '',
  slug: '',
  title: '',
  category: '',
  categorySlug: '',
  description: '',
  pricePerDay: 0,
  deposit: 0,
  city: '',
  ownerName: '',
  rating: 0,
  isAvailable: true,
  images: [],
);

final _rentalCardDecoration = BoxDecoration(
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
