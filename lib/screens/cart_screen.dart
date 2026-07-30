import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/products_api.dart';
import '../widgets/product_media_preview.dart';
import 'rental_contract_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.totalPrice,
  });

  final LendProduct product;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final int totalPrice;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _primaryContainer = Color(0xFF4A70A9);
  static const _secondary = Color(0xFF446085);
  static const _background = Color(0xFFF9F9F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceContainer = Color(0xFFEEEEEE);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _error = Color(0xFFBA1A1A);

  bool _hasItem = true;

  int get _serviceFee => (_hasItem ? widget.totalPrice * 0.05 : 0).round();
  int get _deposit => _hasItem ? widget.product.deposit : 0;
  int get _total => (_hasItem ? widget.totalPrice : 0) + _serviceFee + _deposit;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _CartTopBar()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 40, 20, bottomPadding + 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _CartTitle(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;

                      if (!wide) {
                        return Column(
                          children: [
                            _CartItemsColumn(
                              product: widget.product,
                              hasItem: _hasItem,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              rentalDays: widget.rentalDays,
                              onDelete: _removeItem,
                            ),
                            const SizedBox(height: 24),
                            _OrderSummaryCard(
                              product: widget.product,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              rentalDays: widget.rentalDays,
                              subtotal: _hasItem ? widget.totalPrice : 0,
                              serviceFee: _serviceFee,
                              deposit: _deposit,
                              total: _total,
                              enabled: _hasItem,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _CartItemsColumn(
                              product: widget.product,
                              hasItem: _hasItem,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              rentalDays: widget.rentalDays,
                              onDelete: _removeItem,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: _OrderSummaryCard(
                              product: widget.product,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              rentalDays: widget.rentalDays,
                              subtotal: _hasItem ? widget.totalPrice : 0,
                              serviceFee: _serviceFee,
                              deposit: _deposit,
                              total: _total,
                              enabled: _hasItem,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem() {
    setState(() {
      _hasItem = false;
    });
  }
}

class _CartTopBar extends StatelessWidget {
  const _CartTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _CartScreenState._background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: _CartScreenState._outline.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _CartScreenState._text,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              AppLocalizations.of(context).appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CartScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CartTitle extends StatelessWidget {
  const _CartTitle();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.choose('Cosul meu', 'My cart'),
          style: const TextStyle(
            color: _CartScreenState._text,
            fontSize: 42,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.choose(
            'Gestioneaza produsele tale pregatite pentru inchiriere.',
            'Manage the items prepared for rental.',
          ),
          style: const TextStyle(
            color: _CartScreenState._muted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _CartItemsColumn extends StatelessWidget {
  const _CartItemsColumn({
    required this.product,
    required this.hasItem,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.onDelete,
  });

  final LendProduct product;
  final bool hasItem;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (!hasItem) {
      return const _EmptyCartState();
    }

    return _CartItemCard(
      product: product,
      startDate: startDate,
      endDate: endDate,
      rentalDays: rentalDays,
      onDelete: onDelete,
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.onDelete,
  });

  final LendProduct product;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cartCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final image = _CartProductImage(product: product);
            final details = _CartItemDetails(
              product: product,
              startDate: startDate,
              endDate: endDate,
              rentalDays: rentalDays,
              onDelete: onDelete,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 190, child: image),
                  const SizedBox(height: 20),
                  details,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 160, height: 160, child: image),
                const SizedBox(width: 24),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartProductImage extends StatelessWidget {
  const _CartProductImage({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductMediaPreview(product: product),
          Positioned(
            left: 8,
            top: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _CartScreenState._secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _CartScreenState._secondary.withValues(alpha: 0.20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: _CartScreenState._secondary,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: _CartScreenState._secondary,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _CartItemDetails extends StatelessWidget {
  const _CartItemDetails({
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.onDelete,
  });

  final LendProduct product;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: _CartScreenState._text,
                      fontSize: 24,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.category,
                    style: const TextStyle(
                      color: _CartScreenState._muted,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: _CartScreenState._error,
            ),
          ],
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 18,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CartMetric(
              label: AppLocalizations.of(context).choose('Perioada', 'Period'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: _CartScreenState._text,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}',
                    style: const TextStyle(
                      color: _CartScreenState._text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _CartMetric(
              label: AppLocalizations.of(
                context,
              ).choose('Pret / zi', 'Price / day'),
              bordered: true,
              child: Text(
                '${product.pricePerDay} RON',
                style: const TextStyle(
                  color: _CartScreenState._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _CartMetric(
              label: AppLocalizations.of(context).choose('Durata', 'Duration'),
              bordered: true,
              child: Text(
                AppLocalizations.of(
                  context,
                ).choose('$rentalDays zile', '$rentalDays days'),
                style: const TextStyle(
                  color: _CartScreenState._text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CartMetric extends StatelessWidget {
  const _CartMetric({
    required this.label,
    required this.child,
    this.bordered = false,
  });

  final String label;
  final Widget child;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: bordered
          ? const EdgeInsets.only(left: 16)
          : const EdgeInsets.only(left: 0),
      decoration: BoxDecoration(
        border: bordered
            ? Border(
                left: BorderSide(
                  color: _CartScreenState._outline.withValues(alpha: 0.30),
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF9CA0AA),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.subtotal,
    required this.serviceFee,
    required this.deposit,
    required this.total,
    required this.enabled,
  });

  final LendProduct product;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final int subtotal;
  final int serviceFee;
  final int deposit;
  final int total;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cartCardDecoration.copyWith(
        color: _CartScreenState._surfaceContainer.withValues(alpha: 0.70),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(
                context,
              ).choose('Sumar comanda', 'Order summary'),
              style: const TextStyle(
                color: _CartScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _SummaryRow(
              label: AppLocalizations.of(
                context,
              ).choose('Subtotal', 'Subtotal'),
              value: '$subtotal.00 RON',
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              label: AppLocalizations.of(
                context,
              ).choose('Taxa serviciu', 'Service fee'),
              value: '$serviceFee.00 RON',
              showInfo: true,
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              label: AppLocalizations.of(context).choose('Garantie', 'Deposit'),
              value: '$deposit.00 RON',
              showInfo: true,
            ),
            const SizedBox(height: 22),
            Divider(color: _CartScreenState._outline.withValues(alpha: 0.30)),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).choose('Total', 'Total'),
                    style: const TextStyle(
                      color: _CartScreenState._text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$total.00 RON',
                      style: const TextStyle(
                        color: _CartScreenState._text,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).choose('TVA inclus', 'VAT included'),
                      style: const TextStyle(
                        color: Color(0xFF9CA0AA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: enabled
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RentalContractScreen(
                              product: product,
                              startDate: startDate,
                              endDate: endDate,
                              rentalDays: rentalDays,
                              subtotal: subtotal,
                              serviceFee: serviceFee,
                              total: total,
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _CartScreenState._primaryContainer,
                  disabledBackgroundColor: _CartScreenState._outline.withValues(
                    alpha: 0.40,
                  ),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).choose(
                          'Continua spre checkout',
                          'Continue to checkout',
                        ),
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
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: _CartScreenState._muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).choose('PLATA SECURIZATA', 'SECURE PAYMENT'),
                  style: const TextStyle(
                    color: _CartScreenState._muted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.showInfo = false,
  });

  final String label;
  final String value;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CartScreenState._muted,
                    fontSize: 16,
                  ),
                ),
              ),
              if (showInfo) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF9CA0AA),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _CartScreenState._text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cartCardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: _CartScreenState._outline,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(
                context,
              ).choose('Cosul tau este gol', 'Your cart is empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CartScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).choose(
                'Exploreaza comunitatea si gaseste ce ai nevoie.',
                'Explore the community and find what you need.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CartScreenState._muted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
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

final _cartCardDecoration = BoxDecoration(
  color: _CartScreenState._surface.withValues(alpha: 0.84),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: const Color(0xFFDED9C8).withValues(alpha: 0.30)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ],
);
