import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends State<AvailabilityManagementScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _surface = Color(0xFFF9F9F9);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _manualBlock = Color(0xFF8B5CF6);
  static const _reservation = Color(0xFFDC2626);

  final _rentalOrdersApi = RentalOrdersApi();
  final _reasonController = TextEditingController();

  late DateTime _visibleMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  ProductAvailability? _availability;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadAvailability();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return LendScreenFrame(
      backgroundColor: _background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(title: widget.product.title)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CalendarCard(
                  visibleMonth: _visibleMonth,
                  startDate: _startDate,
                  endDate: _endDate,
                  isLoading: _loading,
                  reservations: _availability?.reservations ?? const [],
                  manualBlocks: _availability?.manualBlocks ?? const [],
                  onPrevious: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                    _loadAvailability();
                  },
                  onNext: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                    _loadAvailability();
                  },
                  onDateSelected: _selectDate,
                ),
                const SizedBox(height: 16),
                _BlockForm(
                  startDate: _startDate,
                  endDate: _endDate,
                  reasonController: _reasonController,
                  saving: _saving,
                  onSubmit: _canSaveBlock ? _createBlock : null,
                ),
                const SizedBox(height: 18),
                _BlocksList(
                  blocks: _availability?.manualBlocks ?? const [],
                  onDelete: _deleteBlock,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSaveBlock {
    return !_saving && _startDate != null && _endDate != null;
  }

  void _selectDate(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    if (_isUnavailableForSelection(selected)) {
      return;
    }

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = selected;
        _endDate = null;
        return;
      }

      if (selected.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = selected;
        return;
      }

      final proposedEnd = selected.isAtSameMomentAs(_startDate!)
          ? selected.add(const Duration(days: 1))
          : selected;
      if (_rangeContainsUnavailable(_startDate!, proposedEnd)) {
        return;
      }

      _endDate = proposedEnd;
    });
  }

  bool _isUnavailableForSelection(DateTime date) {
    final availability = _availability;
    if (availability == null) {
      return false;
    }

    return availability.reservations.any(
          (item) => _isInExclusiveRange(date, item.startDate, item.endDate),
        ) ||
        availability.manualBlocks.any(
          (item) => _isInExclusiveRange(date, item.startDate, item.endDate),
        );
  }

  bool _rangeContainsUnavailable(DateTime startDate, DateTime endDate) {
    final first = startDate.isBefore(endDate) ? startDate : endDate;
    final last = startDate.isBefore(endDate) ? endDate : startDate;

    for (
      var current = first;
      current.isBefore(last);
      current = current.add(const Duration(days: 1))
    ) {
      if (_isUnavailableForSelection(current)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadAvailability() async {
    final from = DateTime(_visibleMonth.year, _visibleMonth.month);
    final to = DateTime(_visibleMonth.year, _visibleMonth.month + 1);

    setState(() {
      _loading = true;
    });

    try {
      final availability = await _rentalOrdersApi.getAvailability(
        productId: widget.product.id,
        from: from,
        to: to,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availability = availability;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
      LendToast.error(context, message: error.toString());
    }
  }

  Future<void> _createBlock() async {
    final startDate = _startDate;
    final endDate = _endDate;
    if (startDate == null || endDate == null) {
      return;
    }

    final token = await AuthSessionStore.getToken();
    if (token == null) {
      if (!mounted) {
        return;
      }
      LendToast.error(
        context,
        message: AppLocalizations.of(
          context,
        ).choose('Trebuie sa fii autentificat.', 'You need to be signed in.'),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _rentalOrdersApi.createAvailabilityBlock(
        accessToken: token,
        productId: widget.product.id,
        startDate: startDate,
        endDate: endDate,
        reason: _reasonController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
      await _loadAvailability();
      if (!mounted) {
        return;
      }
      LendToast.success(
        context,
        message: AppLocalizations.of(
          context,
        ).choose('Perioada a fost blocata.', 'The period has been blocked.'),
      );
    } catch (error) {
      if (mounted) {
        LendToast.error(context, message: error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteBlock(AvailabilityBlock block) async {
    final token = await AuthSessionStore.getToken();
    if (token == null) {
      return;
    }

    try {
      await _rentalOrdersApi.deleteAvailabilityBlock(
        accessToken: token,
        blockId: block.id,
      );
      await _loadAvailability();
    } catch (error) {
      if (mounted) {
        LendToast.error(context, message: error.toString());
      }
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _AvailabilityManagementScreenState._surface.withValues(
          alpha: 0.92,
        ),
        border: Border(
          bottom: BorderSide(
            color: _AvailabilityManagementScreenState._outline.withValues(
              alpha: 0.24,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _AvailabilityManagementScreenState._text,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.choose('Disponibilitate', 'Availability'),
                  style: const TextStyle(
                    color: _AvailabilityManagementScreenState._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AvailabilityManagementScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.startDate,
    required this.endDate,
    required this.isLoading,
    required this.reservations,
    required this.manualBlocks,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final List<AvailabilityReservation> reservations;
  final List<AvailabilityBlock> manualBlocks;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(visibleMonth);

    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMonth(visibleMonth),
                    style: const TextStyle(
                      color: _AvailabilityManagementScreenState._text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _AvailabilityManagementScreenState._primary,
                    ),
                  ),
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _WeekDaysRow(),
            const SizedBox(height: 10),
            GridView.builder(
              itemCount: days.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final date = days[index];
                final inVisibleMonth = date.month == visibleMonth.month;
                final reservation = _isInsideReservation(date);
                final manualBlock = _isInsideManualBlock(date);
                final selected = _isSelectedEndpoint(date);
                final inRange = _isInSelectedRange(date);

                return _DayCell(
                  date: date,
                  inVisibleMonth: inVisibleMonth,
                  reserved: reservation,
                  manuallyBlocked: manualBlock,
                  selected: selected,
                  inRange: inRange,
                  onTap: () => onDateSelected(date),
                );
              },
            ),
            const SizedBox(height: 16),
            const _Legend(),
          ],
        ),
      ),
    );
  }

  bool _isInsideReservation(DateTime date) {
    return reservations.any(
      (item) => _isInExclusiveRange(date, item.startDate, item.endDate),
    );
  }

  bool _isInsideManualBlock(DateTime date) {
    return manualBlocks.any(
      (item) => _isInExclusiveRange(date, item.startDate, item.endDate),
    );
  }

  bool _isSelectedEndpoint(DateTime date) {
    return _isSameDay(date, startDate) || _isSameDay(date, endDate);
  }

  bool _isInSelectedRange(DateTime date) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) {
      return false;
    }
    return date.isAfter(start) && date.isBefore(end);
  }
}

class _BlockForm extends StatelessWidget {
  const _BlockForm({
    required this.startDate,
    required this.endDate,
    required this.reasonController,
    required this.saving,
    required this.onSubmit,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final TextEditingController reasonController;
  final bool saving;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.choose('Blocheaza manual zile', 'Manually block dates'),
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              startDate == null || endDate == null
                  ? strings.choose(
                      'Selecteaza inceputul si finalul perioadei.',
                      'Select the start and end of the period.',
                    )
                  : '${_formatShortDate(startDate!)} - ${_formatShortDate(endDate!)}',
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: strings.choose(
                  'Motiv optional: service, uz personal',
                  'Optional reason: service, personal use',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.block_rounded),
                label: Text(
                  strings.choose('Blocheaza perioada', 'Block period'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _AvailabilityManagementScreenState._primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlocksList extends StatelessWidget {
  const _BlocksList({required this.blocks, required this.onDelete});

  final List<AvailabilityBlock> blocks;
  final ValueChanged<AvailabilityBlock> onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.choose('Blocaje manuale', 'Manual blocks'),
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (blocks.isEmpty)
              Text(
                strings.choose(
                  'Nu ai blocaje manuale in luna aceasta.',
                  'No manual blocks this month.',
                ),
                style: const TextStyle(
                  color: _AvailabilityManagementScreenState._muted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              ...blocks.map(
                (block) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_busy_rounded,
                    color: _AvailabilityManagementScreenState._manualBlock,
                  ),
                  title: Text(
                    '${_formatShortDate(block.startDate)} - ${_formatShortDate(block.endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    block.reason.isEmpty
                        ? strings.choose('Indisponibil', 'Unavailable')
                        : block.reason,
                  ),
                  trailing: IconButton(
                    onPressed: () => onDelete(block),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
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
                  color: _AvailabilityManagementScreenState._muted,
                  fontSize: 12,
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
    required this.reserved,
    required this.manuallyBlocked,
    required this.selected,
    required this.inRange,
    required this.onTap,
  });

  final DateTime date;
  final bool inVisibleMonth;
  final bool reserved;
  final bool manuallyBlocked;
  final bool selected;
  final bool inRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor = _AvailabilityManagementScreenState._text;
    Color background = Colors.transparent;

    if (!inVisibleMonth) {
      textColor = const Color(0x55737781);
    } else if (reserved) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._reservation;
    } else if (manuallyBlocked) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._manualBlock;
    } else if (inRange) {
      background = const Color(0xFFD5E3FF);
    }

    if (selected) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._primary;
    }

    return InkWell(
      onTap: inVisibleMonth && !reserved && !manuallyBlocked ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendItem(
          color: _AvailabilityManagementScreenState._reservation,
          text: 'Inchiriat',
        ),
        SizedBox(width: 14),
        _LegendItem(
          color: _AvailabilityManagementScreenState._manualBlock,
          text: 'Blocat',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 10, height: 10),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: _AvailabilityManagementScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
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

bool _isInExclusiveRange(DateTime date, DateTime? start, DateTime? end) {
  if (start == null || end == null) {
    return false;
  }

  final current = DateTime(date.year, date.month, date.day);
  final rangeStart = DateTime(start.year, start.month, start.day);
  final rangeEnd = DateTime(end.year, end.month, end.day);

  return !current.isBefore(rangeStart) && current.isBefore(rangeEnd);
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

String _formatShortDate(DateTime? date) {
  if (date == null) {
    return '-';
  }

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

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: _AvailabilityManagementScreenState._outline.withValues(alpha: 0.18),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);
