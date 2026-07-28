import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import '../widgets/product_media_preview.dart';
import 'explore_screen.dart';
import 'my_listings_screen.dart';
import 'rentals_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showChrome = true, this.onNavigate});

  final bool showChrome;
  final ValueChanged<int>? onNavigate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _primary = Color(0xFF30578F);
  static const _primaryContainer = Color(0xFF4A70A9);
  static const _background = Color(0xFFEFECE3);
  static const _card = Colors.white;
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _secondary = Color(0xFF446085);
  static const _secondaryContainer = Color(0xFFB7D3FE);
  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD8aP--B20lEnuJhRoH2FnPsbEBgh3Q6Xjixj-YpTcYmcOBDZ8sTny9EzSN46Bz62-7rk6lzIYexOLa_5PN0OSjSpds_9-mhFDha_rHQ-TD9W4Ud6PuYTdTxNmgfedSviWiz_9bMPhJO4qCuj0du2OpMVPGfmYfeSyG60AfkXETwErp2gXPIHHQozlWvCWkgTVfJPI_qGh4Yk7btCDD-KmUyivwldgX0AAk0P6xrPR0Op8hmbIEart4HgI-aa4HF_BYVNw0jjSl1no';

  final _authApi = AuthApi();
  final _productsApi = ProductsApi();
  final _rentalOrdersApi = RentalOrdersApi();
  late Future<_ProfileData> _profileFuture = _loadProfileData();

  Future<_ProfileData> _loadProfileData() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      throw AuthApiException('Trebuie sa fii autentificat.');
    }

    final user = await _authApi.me(token);
    final listings = await _productsApi.findMine(token);
    final rentals = await _rentalOrdersApi.findMine(token);

    return _ProfileData(user: user, listings: listings, rentals: rentals);
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = _loadProfileData();
    });
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
                      title: 'BorrowIt',
                      avatarUrl: _ProfileScreenState._avatarUrl,
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 106)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    widget.showChrome ? 24 : 0,
                    20,
                    widget.showChrome ? 128 : 6,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: FutureBuilder<_ProfileData>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 320,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _ProfileScreenState._primary,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _ProfileMessage(
                            icon: Icons.cloud_off_rounded,
                            title: AppLocalizations.of(context).choose(
                              'Nu am putut incarca profilul',
                              'Could not load profile',
                            ),
                            body: AppLocalizations.of(context).choose(
                              'Verifica backendul si incearca din nou.',
                              'Check the backend and try again.',
                            ),
                            actionLabel: AppLocalizations.of(context).retry,
                            onAction: _reloadProfile,
                          );
                        }

                        final data = snapshot.data!;

                        return Column(
                          children: [
                            _ProfileHeader(data: data),
                            const SizedBox(height: 32),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 760;

                                if (!wide) {
                                  return Column(
                                    children: [
                                      const _ProfileSidebar(),
                                      const SizedBox(height: 20),
                                      _ProfileDashboard(data: data),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 300,
                                      child: _ProfileSidebar(),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _ProfileDashboard(data: data),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showChrome)
              Align(
                alignment: Alignment.bottomCenter,
                child: LendBottomNavigation(
                  currentIndex: 3,
                  onSelected: _handleNavigation,
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
      _replaceWith(context, const ExploreScreen());
    }
    if (index == 1) {
      _replaceWith(context, const MyListingsScreen());
    }
    if (index == 2) {
      _replaceWith(context, const RentalsScreen());
    }
  }

  static void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _ProfileData {
  const _ProfileData({
    required this.user,
    required this.listings,
    required this.rentals,
  });

  final AuthUser user;
  final List<LendProduct> listings;
  final List<RentalOrder> rentals;

  List<RentalOrder> get activeRentals => rentals
      .where(
        (order) =>
            order.status != 'completed' &&
            order.status != 'cancelled' &&
            order.status != 'rejected',
      )
      .toList();

  int get earnedTotal {
    return rentals
        .where((order) => order.status == 'completed')
        .fold<int>(0, (sum, order) => sum + order.subtotal);
  }

  String get ratingLabel {
    if (listings.isEmpty) {
      return '-';
    }

    final rating =
        listings.fold<double>(0, (sum, product) => sum + product.rating) /
        listings.length;
    return rating.toStringAsFixed(1);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.choose('Profilul meu', 'My profile'),
          style: const TextStyle(
            color: _ProfileScreenState._text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              data.user.fullName,
              style: const TextStyle(
                color: _ProfileScreenState._muted,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _ProfileScreenState._secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: _ProfileScreenState._secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      strings.choose(
                        '${data.ratingLabel} (${data.listings.length} anunturi)',
                        '${data.ratingLabel} (${data.listings.length} listings)',
                      ),
                      style: const TextStyle(
                        color: _ProfileScreenState._secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: strings.choose('Obiecte oferite', 'Lent items'),
                value: '${data.listings.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: strings.choose('Castigat', 'Earned'),
                value: '${data.earnedTotal} RON',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF737781),
                fontSize: 11,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProfileScreenState._primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSidebar extends StatelessWidget {
  const _ProfileSidebar();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [_AccountCard(), SizedBox(height: 20), _TrustBadge()],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.choose('CONT & SIGURANTA', 'ACCOUNT & SAFETY'),
              style: const TextStyle(
                color: Color(0xFF737781),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _ActionRow(
              icon: Icons.verified_user_outlined,
              label: strings.choose('Verificare', 'Verification'),
            ),
            _ActionRow(
              icon: Icons.payments_outlined,
              label: strings.choose('Metode de plata', 'Payment methods'),
            ),
            _ActionRow(
              icon: Icons.contact_support_outlined,
              label: strings.choose('Suport', 'Support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: _ProfileScreenState._secondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ProfileScreenState._text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _ProfileScreenState._outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ProfileScreenState._primaryContainer, Color(0xFF8FABD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 42),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            ).choose('Utilizator verificat', 'Verified user'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).choose(
              'Datele sunt sincronizate cu profilul tau din baza de date.',
              'Data is synchronized with your database profile.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDashboard extends StatelessWidget {
  const _ProfileDashboard({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileListingsSection(items: data.listings),
        const SizedBox(height: 40),
        _ActiveRentalSummary(items: data.activeRentals),
      ],
    );
  }
}

class _ProfileListingsSection extends StatelessWidget {
  const _ProfileListingsSection({required this.items});

  final List<LendProduct> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                ).choose('Anunturile mele', 'My listings'),
                style: const TextStyle(
                  color: _ProfileScreenState._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyListingsScreen(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context).choose('Vezi tot', 'See all'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _InlineEmptyState(
            text: AppLocalizations.of(context).choose(
              'Nu ai anunturi publicate.',
              'You have no published listings.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final visibleItems = items.take(4).toList();
              final crossAxisCount = constraints.maxWidth >= 520 ? 2 : 1;

              return GridView.builder(
                itemCount: visibleItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 262,
                ),
                itemBuilder: (context, index) {
                  return _ProfileListingCard(item: visibleItems[index]);
                },
              );
            },
          ),
      ],
    );
  }
}

class _ProfileListingCard extends StatelessWidget {
  const _ProfileListingCard({required this.item});

  final LendProduct item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
          decoration: _profileCardDecoration,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductMediaPreview(product: item),
              Positioned(
                top: 8,
                left: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _ProfileScreenState._primary.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      item.isAvailable ? 'ACTIV' : 'INCHIRIAT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _profileCardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: _ProfileScreenState._text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.pricePerDayLabel,
                      style: const TextStyle(
                        color: _ProfileScreenState._primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveRentalSummary extends StatelessWidget {
  const _ActiveRentalSummary({required this.items});

  final List<RentalOrder> items;

  @override
  Widget build(BuildContext context) {
    final order = items.isEmpty ? null : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          ).choose('Inchirieri active', 'Active rentals'),
          style: const TextStyle(
            color: _ProfileScreenState._text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (order == null)
          _InlineEmptyState(
            text: AppLocalizations.of(
              context,
            ).choose('Nu ai inchirieri active.', 'You have no active rentals.'),
          )
        else
          DecoratedBox(
            decoration: _profileCardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: _ProfileImage(url: order.productImageUrl),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.productTitle.isEmpty
                                    ? 'Produs inchiriat'
                                    : order.productTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ProfileScreenState._text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFF737781),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      order.endDate == null
                                          ? order.status
                                          : AppLocalizations.of(context).choose(
                                              'Returnare: ${_formatShortDate(order.endDate!)}',
                                              'Return: ${_formatShortDate(order.endDate!)}',
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _ProfileScreenState._muted,
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
                  ),
                  Positioned(
                    left: 0,
                    right: MediaQuery.sizeOf(context).width * 0.22,
                    bottom: 0,
                    child: Container(
                      height: 4,
                      color: _ProfileScreenState._primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: _ProfileScreenState._primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileScreenState._muted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileScreenState._primary,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: _ProfileScreenState._primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: _ProfileScreenState._muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFFE2E2E2));
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Color(0xFFE2E2E2));
      },
    );
  }
}

String _formatShortDate(DateTime date) {
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

final _profileCardDecoration = BoxDecoration(
  color: _ProfileScreenState._card,
  border: Border.all(color: _ProfileScreenState._outline),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 20,
      offset: const Offset(0, 2),
    ),
  ],
);
