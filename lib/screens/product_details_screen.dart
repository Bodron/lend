import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/products_api.dart';
import '../widgets/product_media_preview.dart';
import 'rental_period_screen.dart';

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

  static const _ownerImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAPgnU0_oFZ2TNOVbJqPytTt9gv2-H01VfNzs_FAujLByHdiiBrMuNQb5Z_Q_i5FDCmkBYt_se57sFT0HqRoSzbXvCti7x7DFSSFJZUvKb3Ql6bL1TxgtpdljGgWDu5IBUzPpxd_Ztl_yo1BYfrflbQliDHNGXA_to7j5gVKZIg-3uChyuKHD91dtGJCrbTFpklvdKBYW8JGFWu8BN24WPGtdALpY7eDL37sXVZv6fCl588rBrLOjl3Vr_Zz5d-ORanOp_Yu-c9tkg';

  bool _perHour = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final product = widget.product;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _DetailsTopBar()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 116),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HeroImage(product: product),
                      const SizedBox(height: 8),
                      _DetailsInfoCard(
                        product: product,
                        perHour: _perHour,
                        onPriceModeChanged: (value) {
                          setState(() {
                            _perHour = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _SpecsGrid(product: product),
                      const SizedBox(height: 24),
                      _ReviewsSection(product: product),
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
              child: _BottomActionBar(perHour: _perHour, product: product),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsTopBar extends StatelessWidget {
  const _DetailsTopBar();

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
              AppLocalizations.of(
                context,
              ).choose('Detalii produs', 'Product details'),
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
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
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
    required this.perHour,
    required this.onPriceModeChanged,
  });

  final LendProduct product;
  final bool perHour;
  final ValueChanged<bool> onPriceModeChanged;

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
            const SizedBox(height: 24),
            _PriceSwitcher(perHour: perHour, onChanged: onPriceModeChanged),
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
              AppLocalizations.of(
                context,
              ).choose('(produs verificat)', '(verified item)'),
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
          label: AppLocalizations.of(
            context,
          ).choose('Asigurare inclusa', 'Insurance included'),
          color: _ProductDetailsScreenState._text,
        ),
        _StatusBadge(
          icon: Icons.check_circle_outline_rounded,
          label: AppLocalizations.of(
            context,
          ).choose('Disponibil acum', 'Available now'),
          color: Color(0xFF575750),
        ),
        _StatusBadge(
          icon: Icons.near_me_outlined,
          label: product.city,
          color: _ProductDetailsScreenState._secondary,
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

class _PriceSwitcher extends StatelessWidget {
  const _PriceSwitcher({required this.perHour, required this.onChanged});

  final bool perHour;
  final ValueChanged<bool> onChanged;

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
            _SwitchButton(
              label: AppLocalizations.of(context).choose('Pe ora', 'Hourly'),
              selected: perHour,
              onTap: () => onChanged(true),
            ),
            _SwitchButton(
              label: AppLocalizations.of(context).choose('Pe zi', 'Daily'),
              selected: !perHour,
              onTap: () => onChanged(false),
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
        _SectionTitle(
          AppLocalizations.of(context).choose('Descriere', 'Description'),
        ),
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
        AppLocalizations.of(context).choose('Categorie', 'Category'),
        product.category,
      ),
      (
        Icons.location_on_rounded,
        AppLocalizations.of(context).choose('Oras', 'City'),
        product.city,
      ),
      (
        Icons.account_balance_wallet_rounded,
        AppLocalizations.of(context).choose('Garantie', 'Deposit'),
        '${product.deposit} RON',
      ),
      (
        Icons.cleaning_services_rounded,
        AppLocalizations.of(context).choose('Stare', 'Condition'),
        AppLocalizations.of(context).choose('Verificat', 'Verified'),
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
        mainAxisExtent: 116,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _ProductDetailsScreenState._text),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: _ProductDetailsScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProductDetailsScreenState._text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                AppLocalizations.of(context).choose('Recenzii', 'Reviews'),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _ProductDetailsScreenState._text,
              ),
              child: Text(
                AppLocalizations.of(context).choose('Vezi toate', 'See all'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: _cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFB7D3FE),
                      foregroundColor: _ProductDetailsScreenState._text,
                      child: Text('M'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mihai Popescu',
                            style: TextStyle(
                              color: _ProductDetailsScreenState._text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).choose('Review verificat', 'Verified review'),
                            style: const TextStyle(
                              color: _ProductDetailsScreenState._muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.ratingLabel,
                      style: const TextStyle(
                        color: _ProductDetailsScreenState._text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).choose(
                    'Totul a decurs perfect. ${product.ownerName} a predat produsul rapid, iar obiectul a fost conform descrierii.',
                    'Everything went perfectly. ${product.ownerName} handed over the item quickly, and it matched the description.',
                  ),
                  style: const TextStyle(
                    color: _ProductDetailsScreenState._muted,
                    fontSize: 15,
                    height: 1.45,
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
              AppLocalizations.of(context).choose('PROPRIETAR', 'OWNER'),
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
                              AppLocalizations.of(context).choose(
                                'Identitate verificata',
                                'Verified identity',
                              ),
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
                    label: AppLocalizations.of(
                      context,
                    ).choose('Rating', 'Rating'),
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
                    value: '42',
                    label: AppLocalizations.of(
                      context,
                    ).choose('Inchirieri', 'Rentals'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
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
                  AppLocalizations.of(
                    context,
                  ).choose('Trimite mesaj', 'Send message'),
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
                    'BorrowIt Protect',
                    style: TextStyle(
                      color: _ProductDetailsScreenState._secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).choose(
                      'Esti protejat impotriva daunelor accidentale pe toata durata inchirierii.',
                      'You are protected against accidental damage for the entire rental period.',
                    ),
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
  const _BottomActionBar({required this.perHour, required this.product});

  final bool perHour;
  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hourlyPrice = (product.pricePerDay / 8).round().clamp(
      1,
      product.pricePerDay,
    );
    final price = perHour ? '$hourlyPrice RON' : '${product.pricePerDay} RON';
    final unit = perHour
        ? AppLocalizations.of(context).choose('/ ora', '/ hour')
        : AppLocalizations.of(context).choose('/ zi', '/ day');

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 14),
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
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RentalPeriodScreen(product: product),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _ProductDetailsScreenState._primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: _ProductDetailsScreenState._primary.withValues(
                    alpha: 0.20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).choose('Inchiriaza acum', 'Rent now'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
