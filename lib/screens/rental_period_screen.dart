import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/products_api.dart';
import 'cart_screen.dart';

class RentalPeriodScreen extends StatefulWidget {
  const RentalPeriodScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<RentalPeriodScreen> createState() => _RentalPeriodScreenState();
}

class _RentalPeriodScreenState extends State<RentalPeriodScreen> {
  static const _primary = Color(0xFF30578F);
  static const _secondary = Color(0xFF446085);
  static const _background = Color(0xFFEFECE3);
  static const _surface = Color(0xFFF9F9F9);
  static const _surfaceHighest = Color(0xFFE2E2E2);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _primaryFixed = Color(0xFFD5E3FF);

  late DateTime _visibleMonth;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _visibleMonth = DateTime(tomorrow.year, tomorrow.month);
    _startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _endDate = _startDate!.add(const Duration(days: 3));
  }

  int get _rentalDays {
    final start = _startDate;
    final end = _endDate;

    if (start == null || end == null) {
      return 0;
    }

    final days = end.difference(start).inDays;
    return days < 1 ? 1 : days;
  }

  int get _totalPrice => _rentalDays * widget.product.pricePerDay;

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    if (_isUnavailable(date)) {
      return;
    }

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
        return;
      }

      if (date.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = date;
        return;
      }

      _endDate = date;
    });
  }

  bool _isUnavailable(DateTime date) {
    return date.year == 2026 &&
        date.month == 7 &&
        (date.day == 18 || date.day == 19);
  }

  bool _isSelectedEndpoint(DateTime date) {
    return _isSameDay(date, _startDate) || _isSameDay(date, _endDate);
  }

  bool _isInRange(DateTime date) {
    final start = _startDate;
    final end = _endDate;

    if (start == null || end == null) {
      return false;
    }

    return date.isAfter(start) && date.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _PeriodTopBar()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding + 126),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ProductContextCard(product: widget.product),
                      const SizedBox(height: 24),
                      _CalendarCard(
                        visibleMonth: _visibleMonth,
                        startDate: _startDate,
                        endDate: _endDate,
                        onPrevious: _goToPreviousMonth,
                        onNext: _goToNextMonth,
                        onDateSelected: _selectDate,
                        isUnavailable: _isUnavailable,
                        isSelectedEndpoint: _isSelectedEndpoint,
                        isInRange: _isInRange,
                      ),
                      const SizedBox(height: 24),
                      _SummarySection(
                        startDate: _startDate,
                        endDate: _endDate,
                        rentalDays: _rentalDays,
                        totalPrice: _totalPrice,
                      ),
                      const SizedBox(height: 20),
                      const _TrustInfoCard(),
                    ]),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _PeriodActionBar(
                startDate: _startDate,
                endDate: _endDate,
                rentalDays: _rentalDays,
                onContinue: _startDate == null || _endDate == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CartScreen(
                              product: widget.product,
                              startDate: _startDate!,
                              endDate: _endDate!,
                              rentalDays: _rentalDays,
                              totalPrice: _totalPrice,
                            ),
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTopBar extends StatelessWidget {
  const _PeriodTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _RentalPeriodScreenState._surface.withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: _RentalPeriodScreenState._outline.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _RentalPeriodScreenState._primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              ).choose('Alege perioada', 'Choose period'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _RentalPeriodScreenState._primary,
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

class _ProductContextCard extends StatelessWidget {
  const _ProductContextCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _periodCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(color: Color(0xFFE2E2E2));
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _RentalPeriodScreenState._primary,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${product.pricePerDay} RON / zi',
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: _RentalPeriodScreenState._secondary,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Proprietar verificat',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _RentalPeriodScreenState._secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.startDate,
    required this.endDate,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
    required this.isUnavailable,
    required this.isSelectedEndpoint,
    required this.isInRange,
  });

  final DateTime visibleMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime date) isUnavailable;
  final bool Function(DateTime date) isSelectedEndpoint;
  final bool Function(DateTime date) isInRange;

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(visibleMonth);

    return DecoratedBox(
      decoration: _periodCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMonth(visibleMonth),
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _RentalPeriodScreenState._text,
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _RentalPeriodScreenState._text,
                ),
              ],
            ),
            const SizedBox(height: 34),
            const _WeekDaysRow(),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: days.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 0,
              ),
              itemBuilder: (context, index) {
                final date = days[index];
                final inVisibleMonth = date.month == visibleMonth.month;
                final unavailable = isUnavailable(date);

                return _DayCell(
                  date: date,
                  inVisibleMonth: inVisibleMonth,
                  unavailable: unavailable,
                  selectedEndpoint: isSelectedEndpoint(date),
                  inRange: isInRange(date),
                  onTap: () => onDateSelected(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow();

  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _days
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF737781),
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inVisibleMonth,
    required this.unavailable,
    required this.selectedEndpoint,
    required this.inRange,
    required this.onTap,
  });

  final DateTime date;
  final bool inVisibleMonth;
  final bool unavailable;
  final bool selectedEndpoint;
  final bool inRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor = _RentalPeriodScreenState._text;
    Color background = Colors.transparent;

    if (!inVisibleMonth) {
      textColor = const Color(0x55737781);
    } else if (unavailable) {
      textColor = const Color(0x66737781);
    } else if (inRange) {
      textColor = const Color(0xFF1C477D);
      background = _RentalPeriodScreenState._primaryFixed;
    }

    if (selectedEndpoint) {
      textColor = Colors.white;
      background = _RentalPeriodScreenState._primary;
    }

    return InkWell(
      onTap: inVisibleMonth && !unavailable ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontSize: inVisibleMonth ? 14 : 12,
              fontWeight: inVisibleMonth ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.totalPrice,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int rentalDays;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cards = [
          _SummaryCard(
            label: AppLocalizations.of(
              context,
            ).choose('Data inceput', 'Start date'),
            icon: Icons.calendar_today_rounded,
            value: _formatFullDate(startDate),
          ),
          _SummaryCard(
            label: AppLocalizations.of(
              context,
            ).choose('Data sfarsit', 'End date'),
            icon: Icons.event_rounded,
            value: _formatFullDate(endDate),
          ),
          _SummaryCard(
            label: AppLocalizations.of(context).choose(
              'Pret total ($rentalDays zile)',
              'Total price ($rentalDays days)',
            ),
            value: '$totalPrice RON',
            highlighted: true,
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 12)],
            ]..removeLast(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 24),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? _RentalPeriodScreenState._primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? _RentalPeriodScreenState._primary.withValues(alpha: 0.20)
              : _RentalPeriodScreenState._outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: highlighted
                    ? _RentalPeriodScreenState._primary
                    : const Color(0xFF737781),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _RentalPeriodScreenState._primary),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlighted
                          ? _RentalPeriodScreenState._primary
                          : _RentalPeriodScreenState._text,
                      fontSize: highlighted ? 24 : 14,
                      fontWeight: FontWeight.w800,
                    ),
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

class _TrustInfoCard extends StatelessWidget {
  const _TrustInfoCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFB7D3FE),
              foregroundColor: Color(0xFF3F5B80),
              child: Icon(Icons.shield_rounded),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).choose(
                      'Protectie BorrowIt inclusa',
                      'BorrowIt protection included',
                    ),
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).choose(
                      'Inchirierea ta este protejata impotriva daunelor accidentale. Procesul de predare si primire este documentat digital.',
                      'Your rental is protected against accidental damage. Handover and return are documented digitally.',
                    ),
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._muted,
                      fontSize: 16,
                      height: 1.45,
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

class _PeriodActionBar extends StatelessWidget {
  const _PeriodActionBar({
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.onContinue,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int rentalDays;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding + 18),
      decoration: BoxDecoration(
        color: _RentalPeriodScreenState._surface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: _RentalPeriodScreenState._outline.withValues(alpha: 0.20),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final details = _BottomPeriodSummary(
            startDate: startDate,
            endDate: endDate,
            rentalDays: rentalDays,
          );
          final button = SizedBox(
            width: compact ? double.infinity : 230,
            height: 56,
            child: FilledButton.icon(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: _RentalPeriodScreenState._primary,
                disabledBackgroundColor:
                    _RentalPeriodScreenState._surfaceHighest,
                foregroundColor: Colors.white,
                disabledForegroundColor: _RentalPeriodScreenState._muted,
                elevation: 8,
                shadowColor: _RentalPeriodScreenState._primary.withValues(
                  alpha: 0.20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                AppLocalizations.of(
                  context,
                ).choose('Adauga in cos', 'Add to cart'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 14), button],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _BottomPeriodSummary extends StatelessWidget {
  const _BottomPeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int rentalDays;

  @override
  Widget build(BuildContext context) {
    final hasSelection = startDate != null && endDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(
            context,
          ).choose('Perioada selectata', 'Selected period'),
          style: const TextStyle(
            color: Color(0xFF737781),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasSelection
              ? AppLocalizations.of(context).choose(
                  '${_formatShortDate(startDate!)} - ${_formatShortDate(endDate!)} ($rentalDays zile)',
                  '${_formatShortDate(startDate!)} - ${_formatShortDate(endDate!)} ($rentalDays days)',
                )
              : AppLocalizations.of(context).choose(
                  'Alege data de inceput si sfarsit',
                  'Choose start and end date',
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _RentalPeriodScreenState._text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

List<DateTime> _buildCalendarDays(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final startOffset = firstDay.weekday - DateTime.monday;
  final gridStart = firstDay.subtract(Duration(days: startOffset));

  return List.generate(42, (index) => gridStart.add(Duration(days: index)));
}

bool _isSameDay(DateTime date, DateTime? other) {
  return other != null &&
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;
}

String _formatMonth(DateTime date) {
  const months = [
    'Ianuarie',
    'Februarie',
    'Martie',
    'Aprilie',
    'Mai',
    'Iunie',
    'Iulie',
    'August',
    'Septembrie',
    'Octombrie',
    'Noiembrie',
    'Decembrie',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

String _formatFullDate(DateTime? date) {
  if (date == null) {
    return 'Neselectat';
  }

  return '${date.day.toString().padLeft(2, '0')} ${_formatMonth(date)}';
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

final _periodCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: _RentalPeriodScreenState._outline.withValues(alpha: 0.12),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);
