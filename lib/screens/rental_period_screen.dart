import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';

import '../l10n/generated_localizations.dart';
import '../models/rental_mode.dart';
import '../services/rental_orders_api.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/realtime_socket_service.dart';
import '../widgets/lend_screen_frame.dart';
import 'cart_screen.dart';

class RentalPeriodScreen extends StatefulWidget {
  const RentalPeriodScreen({
    super.key,
    required this.product,
    this.rentalMode = RentalMode.day,
    this.initialStartDate,
    this.initialEndDate,
    this.negotiatedSubtotal,
    this.lockSelection = false,
    this.rentalOrdersApi,
    this.enableRealtime = true,
  });

  final LendProduct product;
  final RentalMode rentalMode;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? negotiatedSubtotal;
  final bool lockSelection;
  final RentalOrdersApi? rentalOrdersApi;
  final bool enableRealtime;

  @override
  State<RentalPeriodScreen> createState() => _RentalPeriodScreenState();
}

class _RentalPeriodScreenState extends State<RentalPeriodScreen> {
  static const _primary = Color(0xFF30578F);
  static const _secondary = Color(0xFF446085);
  static const _background = Color(0xFFF5F5F7);
  static const _surface = Color(0xFFF9F9F9);
  static const _surfaceHighest = Color(0xFFE2E2E2);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _primaryFixed = Color(0xFFD5E3FF);

  late DateTime _visibleMonth;
  late DateTime? _startDate;
  late DateTime? _endDate;
  bool _awaitingEndDate = false;
  late String _pickupTime;
  late String _returnTime;
  late final RentalOrdersApi _rentalOrdersApi;
  Set<String> _unavailableDateKeys = {};
  List<AvailabilityReservation> _reservations = const [];
  List<AvailabilityBlock> _manualBlocks = const [];
  bool _availabilityLoading = false;
  String? _availabilityError;
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
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final visibleDate = widget.initialStartDate ?? tomorrow;
    _visibleMonth = DateTime(visibleDate.year, visibleDate.month);
    final initialDate = widget.rentalMode == RentalMode.hour
        ? DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          )
        : DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _startDate = widget.rentalMode == RentalMode.hour
        ? initialDate
        : widget.rentalMode == RentalMode.month
        ? (widget.initialStartDate ?? initialDate)
        : widget.initialStartDate;
    _endDate = widget.rentalMode == RentalMode.hour
        ? initialDate
        : widget.rentalMode == RentalMode.month
        ? (widget.initialEndDate ?? _sameDayNextMonth(initialDate))
        : widget.initialEndDate;
    _awaitingEndDate =
        widget.rentalMode == RentalMode.day &&
        _startDate != null &&
        _endDate == null;
    _pickupTime = widget.product.pickupTime;
    _returnTime = widget.product.returnTime;
    _loadAvailabilityForVisibleMonth();
    if (widget.enableRealtime) _connectAvailabilitySocket();
  }

  @override
  void dispose() {
    _socketRefreshDebounce?.cancel();
    _availabilitySubscription?.cancel();
    _connectionSubscription?.cancel();
    if (_joinedAvailability) _realtime.leaveAvailability(widget.product.id);
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
      if (mounted) _loadAvailabilityForVisibleMonth();
    });
  }

  int get _rentalDays {
    final start = _startDate;
    final end = _endDate;

    if (start == null || end == null) {
      return 0;
    }

    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    return days < 1 ? 1 : days;
  }

  int get _totalPrice => widget.rentalMode == RentalMode.month
      ? (widget.product.pricePerMonth ?? 0)
      : _rentalDays * widget.product.pricePerDay;

  DateTime _sameDayNextMonth(DateTime date) {
    final next = DateTime(date.year, date.month + 1, 1);
    final lastDay = DateTime(next.year, next.month + 1, 0).day;
    return DateTime(next.year, next.month, date.day.clamp(1, lastDay));
  }

  int get _hourlyPrice {
    return (widget.product.pricePerDay / 8).round().clamp(
      1,
      widget.product.pricePerDay,
    );
  }

  int get _rentalHours {
    final start = _startDate;
    final end = _endDate;

    if (start == null || end == null) {
      return 0;
    }

    final startDateTime = _combineDateAndTime(start, _pickupTime);
    final endDateTime = _combineDateAndTime(end, _returnTime);
    final hours = endDateTime.difference(startDateTime).inMinutes / 60;

    return hours <= 0 ? 0 : hours.ceil();
  }

  int get _checkoutTotalPrice {
    if (widget.rentalMode == RentalMode.hour) {
      return _rentalHours * _hourlyPrice;
    }

    return widget.negotiatedSubtotal ?? _totalPrice;
  }

  List<String> get _availableTimeOptions {
    final first = _timeToMinutes(widget.product.pickupTime);
    final last = _timeToMinutes(widget.product.returnTime);
    return _TimeSelectionCard.timeOptions.where((value) {
      final minutes = _timeToMinutes(value);
      return minutes >= first && minutes <= last;
    }).toList();
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
    _loadAvailabilityForVisibleMonth();
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
    _loadAvailabilityForVisibleMonth();
  }

  void _selectDate(DateTime date) {
    if (_isUnavailable(date)) {
      return;
    }

    setState(() {
      if (widget.rentalMode == RentalMode.hour) {
        _startDate = date;
        _endDate = date;
        return;
      }
      if (widget.rentalMode == RentalMode.month) {
        final end = _sameDayNextMonth(date);
        if (_rangeContainsUnavailable(date, end)) return;
        _startDate = date;
        _endDate = end;
        return;
      }
      if (_startDate == null || !_awaitingEndDate) {
        _startDate = date;
        _endDate = date;
        _awaitingEndDate = true;
        return;
      }

      if (date.isBefore(_startDate!)) {
        if (_rangeContainsUnavailable(date, _startDate!)) return;
        _endDate = _startDate;
        _startDate = date;
        _awaitingEndDate = false;
        return;
      }

      if (_rangeContainsUnavailable(_startDate!, date)) {
        return;
      }

      _endDate = date;
      _awaitingEndDate = false;
    });
  }

  bool _isUnavailable(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final current = _dateOnly(date);
    if (current.isBefore(today)) return true;
    if (widget.rentalMode == RentalMode.hour) {
      return _manualBlocks.any(
        (block) =>
            block.startDate != null &&
            block.endDate != null &&
            !current.isBefore(block.startDate!) &&
            current.isBefore(block.endDate!),
      );
    }
    return _unavailableDateKeys.contains(_dateKey(current));
  }

  bool _rangeContainsUnavailable(DateTime startDate, DateTime endDate) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final first = start.isBefore(end) ? start : end;
    final last = start.isBefore(end) ? end : start;

    for (
      var current = first;
      current.isBefore(last);
      current = current.add(const Duration(days: 1))
    ) {
      if (_isUnavailable(current)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadAvailabilityForVisibleMonth() async {
    final requestId = ++_availabilityRequestId;
    final firstMonth =
        _startDate == null || !_startDate!.isBefore(_visibleMonth)
        ? _visibleMonth
        : DateTime(_startDate!.year, _startDate!.month);
    final from = DateTime(firstMonth.year, firstMonth.month);
    // Keep the selected start month in the availability window when the user
    // moves forward to choose an end date in a later month.
    final to = DateTime(_visibleMonth.year, _visibleMonth.month + 2);

    setState(() {
      _availabilityLoading = true;
      _availabilityError = null;
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
        _unavailableDateKeys = availability.unavailableDates;
        _reservations = availability.reservations;
        _manualBlocks = availability.manualBlocks;
        _availabilityLoading = false;

        // Nu păstrăm o perioadă implicită/anterioară dacă API-ul a marcat
        // una dintre zile ca fiind deja ocupată.
        if ((_startDate != null && _isUnavailable(_startDate!)) ||
            (_endDate != null && _isUnavailable(_endDate!)) ||
            (_startDate != null &&
                _endDate != null &&
                _rangeContainsUnavailable(_startDate!, _endDate!))) {
          _startDate = null;
          _endDate = null;
          _awaitingEndDate = false;
        }

        if (widget.rentalMode == RentalMode.hour && _startDate == null) {
          final firstAvailable = _findFirstAvailableDate(from);
          if (firstAvailable != null) {
            _startDate = firstAvailable;
            _endDate = firstAvailable;
          }
        }
      });
    } catch (error) {
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _availabilityError = error.toString();
        _availabilityLoading = false;
      });
    }
  }

  DateTime? _findFirstAvailableDate(DateTime from) {
    for (var offset = 0; offset < 31; offset++) {
      final date = _dateOnly(from.add(Duration(days: offset)));
      if (!_isUnavailable(date)) return date;
    }
    return null;
  }

  bool _isSelectedEndpoint(DateTime date) {
    return !_isUnavailable(date) &&
        (_isSameDay(date, _startDate) || _isSameDay(date, _endDate));
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

    return LendScreenFrame(
      backgroundColor: _background,
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
                      onPrevious: widget.lockSelection
                          ? () {}
                          : _goToPreviousMonth,
                      onNext: widget.lockSelection ? () {} : _goToNextMonth,
                      onDateSelected: widget.lockSelection
                          ? (_) {}
                          : _selectDate,
                      isUnavailable: _isUnavailable,
                      isSelectedEndpoint: _isSelectedEndpoint,
                      isInRange: _isInRange,
                      hourlyMode: widget.rentalMode == RentalMode.hour,
                      awaitingEndDate: _awaitingEndDate,
                      isLoading: _availabilityLoading,
                      error: _availabilityError,
                    ),
                    if (widget.rentalMode == RentalMode.hour) ...[
                      const SizedBox(height: 24),
                      _TimeSelectionCard(
                        pickupTime: _pickupTime,
                        returnTime: _returnTime,
                        options: _availableTimeOptions,
                        isUnavailable: _isHourUnavailable,
                        onPickupChanged: (value) => setState(() {
                          _pickupTime = value;
                        }),
                        onReturnChanged: (value) => setState(() {
                          _returnTime = value;
                        }),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SummarySection(
                      startDate: _startDate,
                      endDate: _endDate,
                      pickupTime: _pickupTime,
                      returnTime: _returnTime,
                      rentalMode: widget.rentalMode,
                      rentalHours: _rentalHours,
                      rentalDays: _rentalDays,
                      totalPrice: _checkoutTotalPrice,
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
              onContinue:
                  _startDate == null ||
                      _endDate == null ||
                      (widget.rentalMode == RentalMode.hour &&
                          _rentalHours <= 0)
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CartScreen(
                            product: widget.product,
                            rentalMode: widget.rentalMode,
                            startDate: _startDate!,
                            endDate: _endDate!,
                            pickupTime: _pickupTime,
                            returnTime: _returnTime,
                            rentalHours: _rentalHours,
                            rentalDays: _rentalDays,
                            totalPrice: _checkoutTotalPrice,
                            negotiatedSubtotal: widget.negotiatedSubtotal,
                          ),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  bool _isHourUnavailable(String time) {
    final date = _startDate;
    if (date == null) return true;
    final selectedMinutes = _timeToMinutes(time);
    final occupied = _reservations.where((item) {
      if (item.occupiedFrom != null && item.occupiedUntil != null) {
        final selectedAt = DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).add(Duration(minutes: selectedMinutes));
        return !selectedAt.isBefore(item.occupiedFrom!) &&
            selectedAt.isBefore(item.occupiedUntil!);
      }
      if (item.startDate == null || item.endDate == null) return false;
      if (!_isSameDay(date, item.startDate) ||
          !_isSameDay(date, item.endDate)) {
        return item.startDate!.isBefore(date.add(const Duration(days: 1))) &&
            item.endDate!.isAfter(date);
      }
      return selectedMinutes >= _timeToMinutes(item.pickupTime) &&
          selectedMinutes < _timeToMinutes(item.returnTime) + 60;
    }).length;
    return occupied >= widget.product.stockQuantity;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

DateTime _combineDateAndTime(DateTime date, String time) {
  final parts = time.split(':');
  final hours = int.tryParse(parts.first) ?? 0;
  final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  return DateTime(date.year, date.month, date.day, hours, minutes);
}

class _PeriodTopBar extends StatelessWidget {
  const _PeriodTopBar();

  @override
  Widget build(BuildContext context) {
    return LendBackTopBar(
      title: GeneratedLocalizations.of(context).choosePeriod,
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
                      color: _RentalPeriodScreenState._text,
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
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: _RentalPeriodScreenState._secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          GeneratedLocalizations.of(context).ownerVerified,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
    required this.hourlyMode,
    required this.awaitingEndDate,
    required this.isLoading,
    required this.error,
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
  final bool hourlyMode;
  final bool awaitingEndDate;
  final bool isLoading;
  final String? error;

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
                    _formatMonth(context, visibleMonth),
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
            if (isLoading || error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _RentalPeriodScreenState._primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: _RentalPeriodScreenState._muted,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLoading
                          ? GeneratedLocalizations.of(
                              context,
                            ).checkingAvailability
                          : GeneratedLocalizations.of(
                              context,
                            ).availabilityRefreshError,
                      style: const TextStyle(
                        color: _RentalPeriodScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 34),
            if (hourlyMode)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  GeneratedLocalizations.of(context).selectDayAndTime,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            if (awaitingEndDate)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  GeneratedLocalizations.of(context).chooseEndDate,
                  style: const TextStyle(
                    color: _RentalPeriodScreenState._secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
      textColor = const Color(0x88737781);
      background = const Color(0xFFE7E7E9);
    } else if (inRange) {
      textColor = _RentalPeriodScreenState._text;
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
              decoration: unavailable && inVisibleMonth
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSelectionCard extends StatelessWidget {
  const _TimeSelectionCard({
    required this.pickupTime,
    required this.returnTime,
    required this.onPickupChanged,
    required this.onReturnChanged,
    required this.isUnavailable,
    required this.options,
  });

  static const timeOptions = [
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  final String pickupTime;
  final String returnTime;
  final ValueChanged<String> onPickupChanged;
  final ValueChanged<String> onReturnChanged;
  final bool Function(String time) isUnavailable;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _periodCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: _RentalPeriodScreenState._text,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GeneratedLocalizations.of(context).chooseHours,
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TimeSelector(
              label: GeneratedLocalizations.of(context).pickup,
              value: pickupTime,
              options: options,
              onChanged: onPickupChanged,
              isUnavailable: isUnavailable,
            ),
            const SizedBox(height: 16),
            _TimeSelector(
              label: GeneratedLocalizations.of(context).returnLabel,
              value: returnTime,
              options: options,
              onChanged: onReturnChanged,
              isUnavailable: isUnavailable,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isUnavailable,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool Function(String time) isUnavailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _RentalPeriodScreenState._muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = option == value;

              return ChoiceChip(
                label: Text(option),
                selected: selected,
                showCheckmark: false,
                onSelected: isUnavailable(option)
                    ? null
                    : (_) => onChanged(option),
                selectedColor: _RentalPeriodScreenState._primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : isUnavailable(option)
                      ? _RentalPeriodScreenState._muted.withValues(alpha: 0.45)
                      : _RentalPeriodScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected
                      ? _RentalPeriodScreenState._primary
                      : _RentalPeriodScreenState._outline.withValues(
                          alpha: 0.40,
                        ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.returnTime,
    required this.rentalMode,
    required this.rentalHours,
    required this.rentalDays,
    required this.totalPrice,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String pickupTime;
  final String returnTime;
  final RentalMode rentalMode;
  final int rentalHours;
  final int rentalDays;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cards = [
          _SummaryCard(
            label: GeneratedLocalizations.of(context).startDate,
            icon: Icons.calendar_today_rounded,
            value: '${_formatFullDate(context, startDate)}\n$pickupTime',
          ),
          _SummaryCard(
            label: GeneratedLocalizations.of(context).endDate,
            icon: Icons.event_rounded,
            value: '${_formatFullDate(context, endDate)}\n$returnTime',
          ),
          _SummaryCard(
            label: GeneratedLocalizations.of(context).totalPriceWithDuration(
              rentalMode == RentalMode.hour
                  ? GeneratedLocalizations.of(context).hoursCount(rentalHours)
                  : rentalMode == RentalMode.month
                  ? GeneratedLocalizations.of(context).oneMonth
                  : GeneratedLocalizations.of(context).daysCount(rentalDays),
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
                    ? _RentalPeriodScreenState._text
                    : const Color(0xFF737781),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _RentalPeriodScreenState._text),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlighted
                          ? _RentalPeriodScreenState._text
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
              foregroundColor: _RentalPeriodScreenState._text,
              child: Icon(Icons.shield_rounded),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GeneratedLocalizations.of(context).lendProtectionIncluded,
                    style: const TextStyle(
                      color: _RentalPeriodScreenState._text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    GeneratedLocalizations.of(context).lendProtectionBody,
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
                GeneratedLocalizations.of(context).addToCart,
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
          GeneratedLocalizations.of(context).selectedPeriod,
          style: const TextStyle(
            color: Color(0xFF737781),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasSelection
              ? GeneratedLocalizations.of(context).selectedPeriodWithDays(
                  _formatShortDate(context, startDate!),
                  _formatShortDate(context, endDate!),
                  rentalDays,
                )
              : GeneratedLocalizations.of(context).chooseStartAndEndDate,
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

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
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

String _formatFullDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return GeneratedLocalizations.of(context).notSelected;
  }

  return '${date.day.toString().padLeft(2, '0')} ${_formatMonth(context, date)}';
}

String _formatShortDate(BuildContext context, DateTime date) {
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
