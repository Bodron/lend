import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';

import '../l10n/generated_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../services/realtime_socket_service.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({
    super.key,
    required this.product,
    this.rentalOrdersApi,
    this.enableRealtime = true,
  });

  final LendProduct product;
  final RentalOrdersApi? rentalOrdersApi;
  final bool enableRealtime;

  @override
  State<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends State<AvailabilityManagementScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _manualBlock = Color(0xFF8B5CF6);
  static const _reservation = Color(0xFFDC2626);

  late final RentalOrdersApi _rentalOrdersApi;
  final _reasonController = TextEditingController();

  late DateTime _visibleMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _awaitingEndDate = false;
  ProductAvailability? _availability;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  int _availabilityRequestId = 0;
  final _realtime = RealtimeSocketService.instance;
  RealtimeSubscription? _availabilitySubscription;
  RealtimeSubscription? _connectionSubscription;
  Timer? _socketRefreshDebounce;
  bool _joinedAvailability = false;

  @override
  void initState() {
    super.initState();
    _rentalOrdersApi = widget.rentalOrdersApi ?? RentalOrdersApi();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadAvailability();
    if (widget.enableRealtime) _connectAvailabilitySocket();
  }

  @override
  void dispose() {
    _socketRefreshDebounce?.cancel();
    _availabilitySubscription?.cancel();
    _connectionSubscription?.cancel();
    if (_joinedAvailability) _realtime.leaveAvailability(widget.product.id);
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _connectAvailabilitySocket() async {
    final token = await AuthSessionStore.getToken();
    if (!mounted || token == null) return;
    try {
      final subscription = await _realtime.subscribe(
        accessToken: token,
        apiBaseUrl: AuthApi.baseUrl,
        event: RealtimeEvents.availabilityChanged,
        onData: (data) {
          if (data is Map && data['productId'] == widget.product.id) {
            _refreshAvailabilityFromSocket();
          }
        },
      );
      if (!mounted) {
        subscription.cancel();
        return;
      }
      _availabilitySubscription = subscription;
      final connection = await _realtime.subscribe(
        accessToken: token,
        apiBaseUrl: AuthApi.baseUrl,
        event: 'connect',
        onData: (_) => _refreshAvailabilityFromSocket(),
      );
      if (!mounted) {
        connection.cancel();
        return;
      }
      _connectionSubscription = connection;
      _realtime.joinAvailability(widget.product.id);
      _joinedAvailability = true;
      _refreshAvailabilityFromSocket();
    } catch (error) {
      debugPrint('Realtime availability unavailable: $error');
    }
  }

  void _refreshAvailabilityFromSocket() {
    _socketRefreshDebounce?.cancel();
    _socketRefreshDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _loadAvailability();
    });
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
                  loadError: _loadError,
                  canSelect:
                      _availability != null && !_loading && _loadError == null,
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
                  onRetry: _loadAvailability,
                ),
                const SizedBox(height: 16),
                _BlockForm(
                  startDate: _startDate,
                  endDate: _endDate,
                  awaitingEndDate: _awaitingEndDate,
                  reasonController: _reasonController,
                  saving: _saving,
                  onSubmit: _canSaveBlock ? _createBlock : null,
                ),
                const SizedBox(height: 18),
                _BlocksList(blocks: _displayedBlocks, onDelete: _deleteBlock),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSaveBlock {
    return !_saving &&
        !_loading &&
        _loadError == null &&
        _startDate != null &&
        _endDate != null;
  }

  List<AvailabilityBlock> get _displayedBlocks {
    final days = _buildCalendarDays(_visibleMonth);
    final firstDay = days.first;
    final lastDay = days.last;
    final afterLastDay = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    return (_availability?.manualBlocks ?? const <AvailabilityBlock>[])
        .where(
          (block) =>
              block.startDate != null &&
              block.endDate != null &&
              block.startDate!.isBefore(afterLastDay) &&
              block.endDate!.isAfter(firstDay),
        )
        .toList();
  }

  void _selectDate(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    if (_isUnavailableForSelection(selected)) {
      return;
    }

    setState(() {
      if (_startDate == null || !_awaitingEndDate) {
        _startDate = selected;
        _endDate = selected;
        _awaitingEndDate = true;
        return;
      }

      if (selected.isBefore(_startDate!)) {
        if (_rangeContainsUnavailable(selected, _startDate!)) return;
        _endDate = _startDate;
        _startDate = selected;
        _awaitingEndDate = false;
        return;
      }

      if (_rangeContainsUnavailable(_startDate!, selected)) {
        return;
      }

      _endDate = selected;
      _awaitingEndDate = false;
    });
  }

  bool _isUnavailableForSelection(DateTime date) {
    final today = DateTime.now();
    final currentDay = DateTime(date.year, date.month, date.day);
    if (currentDay.isBefore(DateTime(today.year, today.month, today.day)) ||
        _loading ||
        _loadError != null) {
      return true;
    }
    final availability = _availability;
    if (availability == null) {
      return true;
    }

    return availability.reservations.any(
          (item) => _reservationOverlapsDate(date, item),
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
      !current.isAfter(last);
      current = DateTime(current.year, current.month, current.day + 1)
    ) {
      if (_isUnavailableForSelection(current)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadAvailability() async {
    final requestId = ++_availabilityRequestId;
    final days = _buildCalendarDays(_visibleMonth);
    final firstDay = days.first;
    final lastDay = days.last;
    final from = _startDate != null && _startDate!.isBefore(firstDay)
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
        : firstDay;
    final to = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final availability = await _rentalOrdersApi.getAvailability(
        productId: widget.product.id,
        from: from,
        to: to,
      );

      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _availability = availability;
        _loading = false;
        _loadError = null;
        if (_startDate != null &&
            _endDate != null &&
            _rangeContainsUnavailable(_startDate!, _endDate!)) {
          _startDate = null;
          _endDate = null;
          _awaitingEndDate = false;
        }
      });
    } catch (error) {
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _loading = false;
        _loadError = error.toString();
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
        message: GeneratedLocalizations.of(context).signInRequired,
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
        endDate: DateTime(endDate.year, endDate.month, endDate.day + 1),
        reason: _reasonController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _startDate = null;
        _endDate = null;
        _awaitingEndDate = false;
        _reasonController.clear();
      });
      await _loadAvailability();
      if (!mounted) {
        return;
      }
      LendToast.success(
        context,
        message: GeneratedLocalizations.of(context).periodBlocked,
      );
    } catch (error) {
      if (mounted) {
        await _loadAvailability();
      }
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
    return LendBackTopBar(
      title: GeneratedLocalizations.of(context).availability,
      subtitle: title,
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.startDate,
    required this.endDate,
    required this.isLoading,
    required this.loadError,
    required this.canSelect,
    required this.reservations,
    required this.manualBlocks,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
    required this.onRetry,
  });

  final DateTime visibleMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final String? loadError;
  final bool canSelect;
  final List<AvailabilityReservation> reservations;
  final List<AvailabilityBlock> manualBlocks;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(visibleMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
                    _formatMonth(context, visibleMonth),
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
            if (loadError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      GeneratedLocalizations.of(
                        context,
                      ).availabilityRefreshError,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(GeneratedLocalizations.of(context).retry),
                  ),
                ],
              ),
            ],
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
                final isPast = date.isBefore(today);
                final reservation = _isInsideReservation(date);
                final manualBlock = _isInsideManualBlock(date);
                final selected = _isSelectedEndpoint(date);
                final inRange = _isInSelectedRange(date);

                return _DayCell(
                  date: date,
                  inVisibleMonth: inVisibleMonth,
                  isPast: isPast,
                  canSelect: canSelect,
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
    return reservations.any((item) => _reservationOverlapsDate(date, item));
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
    required this.awaitingEndDate,
    required this.reasonController,
    required this.saving,
    required this.onSubmit,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final bool awaitingEndDate;
  final TextEditingController reasonController;
  final bool saving;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.manualBlockDates,
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              startDate == null || endDate == null
                  ? strings.selectPeriodStartEnd
                  : _formatSelectedDays(context, startDate!, endDate!),
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (awaitingEndDate) ...[
              const SizedBox(height: 4),
              Text(
                strings.chooseRangeEnd,
                style: const TextStyle(
                  color: _AvailabilityManagementScreenState._muted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              strings.blockBookedDayHint,
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: strings.availabilityReasonHint,
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
                  startDate != null &&
                          endDate != null &&
                          _isSameDay(startDate!, endDate!)
                      ? strings.blockDay
                      : strings.blockPeriod,
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
    final strings = GeneratedLocalizations.of(context);

    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.manualBlocks,
              style: const TextStyle(
                color: _AvailabilityManagementScreenState._text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (blocks.isEmpty)
              Text(
                strings.noManualBlocksThisMonth,
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
                    _formatBlockedDays(context, block),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    block.reason.isEmpty ? strings.unavailable : block.reason,
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
    required this.isPast,
    required this.canSelect,
    required this.reserved,
    required this.manuallyBlocked,
    required this.selected,
    required this.inRange,
    required this.onTap,
  });

  final DateTime date;
  final bool inVisibleMonth;
  final bool isPast;
  final bool canSelect;
  final bool reserved;
  final bool manuallyBlocked;
  final bool selected;
  final bool inRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor = _AvailabilityManagementScreenState._text;
    Color background = Colors.transparent;

    if (isPast) {
      textColor = const Color(0x55737781);
    } else if (reserved) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._reservation;
    } else if (manuallyBlocked) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._manualBlock;
    } else if (inRange) {
      background = const Color(0xFFD5E3FF);
    } else if (!inVisibleMonth) {
      textColor = const Color(0xFF6B7280);
    }

    if (selected && !isPast) {
      textColor = Colors.white;
      background = _AvailabilityManagementScreenState._primary;
    }

    return InkWell(
      onTap: !isPast && canSelect && !reserved && !manuallyBlocked
          ? onTap
          : null,
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
    final strings = GeneratedLocalizations.of(context);

    return Row(
      children: [
        _LegendItem(
          color: _AvailabilityManagementScreenState._reservation,
          text: strings.rented,
        ),
        const SizedBox(width: 14),
        _LegendItem(
          color: _AvailabilityManagementScreenState._manualBlock,
          text: strings.blocked,
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

  return !current.isBefore(rangeStart) &&
      (current.isBefore(rangeEnd) ||
          (rangeStart.isAtSameMomentAs(rangeEnd) &&
              current.isAtSameMomentAs(rangeStart)));
}

bool _reservationOverlapsDate(DateTime date, AvailabilityReservation item) {
  final occupiedFrom = item.occupiedFrom;
  final occupiedUntil = item.occupiedUntil;
  if (occupiedFrom != null && occupiedUntil != null) {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return occupiedFrom.isBefore(end) && occupiedUntil.isAfter(start);
  }
  return _isInExclusiveRange(date, item.startDate, item.endDate);
}

String _formatMonth(BuildContext context, DateTime date) {
  final strings = GeneratedLocalizations.of(context);
  final months = [
    strings.january,
    strings.february,
    strings.march,
    strings.april,
    strings.may,
    strings.june,
    strings.july,
    strings.august,
    strings.september,
    strings.october,
    strings.november,
    strings.december,
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _formatSelectedDays(BuildContext context, DateTime start, DateTime end) {
  final first = _formatShortDate(context, start);
  return _isSameDay(start, end)
      ? first
      : '$first - ${_formatShortDate(context, end)}';
}

String _formatBlockedDays(BuildContext context, AvailabilityBlock block) {
  final start = block.startDate;
  final exclusiveEnd = block.endDate;
  if (start == null || exclusiveEnd == null) return '-';
  final lastDay = DateTime(
    exclusiveEnd.year,
    exclusiveEnd.month,
    exclusiveEnd.day - 1,
  );
  return _formatSelectedDays(
    context,
    start,
    lastDay.isBefore(start) ? start : lastDay,
  );
}

String _formatShortDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return '-';
  }

  final strings = GeneratedLocalizations.of(context);
  final months = [
    strings.janShort,
    strings.febShort,
    strings.marShort,
    strings.aprShort,
    strings.mayShort,
    strings.junShort,
    strings.julShort,
    strings.augShort,
    strings.sepShort,
    strings.octShort,
    strings.novShort,
    strings.decShort,
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
