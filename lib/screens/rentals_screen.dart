import 'dart:async';

import 'package:flutter/material.dart';

import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'my_listings_screen.dart';
import 'profile_screen.dart';
import 'return_qr_screen.dart';
import 'return_scan_screen.dart';
import '../l10n/generated_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/realtime_socket_service.dart';
import '../services/rental_orders_api.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';
import '../widgets/lend_top_bar.dart';
import '../widgets/product_media_preview.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({
    super.key,
    this.showChrome = true,
    this.onNavigate,
    this.initialRentalOrderId,
    this.initialShowOwnedRentals = false,
    this.onRentalOpened,
  });

  final bool showChrome;
  final ValueChanged<int>? onNavigate;
  final String? initialRentalOrderId;
  final bool initialShowOwnedRentals;
  final VoidCallback? onRentalOpened;

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
  final _realtime = RealtimeSocketService.instance;
  RealtimeSubscription? _rentalSubscription;
  RealtimeSubscription? _connectionSubscription;
  Timer? _socketRefreshDebounce;
  late Future<_RentalsData> _orders = _loadOrders();
  String? _pendingRentalOrderId;
  final Map<String, GlobalKey> _rentalKeys = {};

  @override
  void didUpdateWidget(covariant RentalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRentalOrderId != oldWidget.initialRentalOrderId &&
        widget.initialRentalOrderId != null) {
      _pendingRentalOrderId = widget.initialRentalOrderId;
    }
    if (widget.initialShowOwnedRentals != oldWidget.initialShowOwnedRentals &&
        widget.initialShowOwnedRentals) {
      _perspective = _RentalPerspective.lending;
      _showHistory = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pendingRentalOrderId = widget.initialRentalOrderId;
    _perspective = widget.initialShowOwnedRentals
        ? _RentalPerspective.lending
        : _RentalPerspective.renting;
    _connectRentalSocket();
  }

  @override
  void dispose() {
    _socketRefreshDebounce?.cancel();
    _rentalSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectRentalSocket() async {
    final token = await AuthSessionStore.getToken();

    if (!mounted || token == null) {
      return;
    }

    try {
      _rentalSubscription = await _realtime.subscribeToEvents(
        accessToken: token,
        apiBaseUrl: AuthApi.baseUrl,
        events: RealtimeEvents.rentalOrderEvents,
        onData: (_, _) => _refreshOrdersFromSocket(),
      );
      _connectionSubscription = await _realtime.subscribe(
        accessToken: token,
        apiBaseUrl: AuthApi.baseUrl,
        event: 'connect',
        onData: (_) => _refreshOrdersFromSocket(),
      );
    } catch (error) {
      debugPrint('Realtime rentals unavailable: $error');
    }
  }

  void _refreshOrdersFromSocket() {
    _socketRefreshDebounce?.cancel();
    _socketRefreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _reloadOrders();
    });
  }

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

  void _focusPendingRental(List<_RentalItem> items) {
    final orderId = _pendingRentalOrderId;
    if (!mounted || orderId == null) return;

    final item = items.where((value) => value.id == orderId).firstOrNull;
    if (item == null) return;

    final key = _rentalKeys.putIfAbsent(orderId, GlobalKey.new);
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    _pendingRentalOrderId = null;
    widget.onRentalOpened?.call();
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  static bool _isHistoryOrder(RentalOrder order) {
    return order.status == 'completed' ||
        order.status == 'cancelled' ||
        order.status == 'rejected';
  }

  static _RentalItem _rentalItemFromOrder(
    RentalOrder order,
    _RentalPerspective perspective,
    GeneratedLocalizations strings,
  ) {
    final expiring = order.endDate != null && _isToday(order.endDate!);
    final ownerName = order.productOwnerName.isEmpty
        ? strings.ownerDefaultName
        : order.productOwnerName;
    final renterName = order.renterName.isEmpty
        ? strings.renterDefaultName
        : order.renterName;

    return _RentalItem(
      id: order.id,
      title: order.productTitle.isEmpty
          ? strings.rentedProductDefaultTitle
          : order.productTitle,
      dateText: order.endDate == null
          ? strings.submittedOrder
          : strings.untilDate(_formatShortDate(strings, order.endDate!)),
      scheduleText: order.startDate == null || order.endDate == null
          ? strings.rentalSchedule(order.pickupTime, order.returnTime)
          : strings.pickupReturnSchedule(
              _formatShortDate(strings, order.startDate!),
              order.pickupTime,
              _formatShortDate(strings, order.endDate!),
              order.returnTime,
            ),
      pickupTime: order.pickupTime,
      returnTime: order.returnTime,
      imageUrl: order.productImageUrl,
      imageContentType: order.productImageContentType,
      imageType: order.productImageType,
      detailText: perspective == _RentalPerspective.renting
          ? strings.fromOwner(ownerName)
          : strings.renterLabel(renterName),
      statusRaw: order.status,
      paymentStatus: order.paymentStatus,
      status: expiring ? _RentalStatus.expiring : _RentalStatus.active,
    );
  }

  static _RentalHistoryItem _historyItemFromOrder(
    RentalOrder order,
    GeneratedLocalizations strings,
  ) {
    final start = order.startDate;
    final end = order.endDate;

    return _RentalHistoryItem(
      title: order.productTitle.isEmpty
          ? strings.rentedProductDefaultTitle
          : order.productTitle,
      dateText: start == null || end == null
          ? strings.completedRental
          : strings.rentedDateRange(
              _formatShortDate(strings, start),
              _formatShortDate(strings, end),
            ),
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

  static String _formatShortDate(
    GeneratedLocalizations strings,
    DateTime date,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        CustomScrollView(
          slivers: [
            if (widget.showChrome)
              const SliverToBoxAdapter(
                child: LendTopBar(
                  title: 'Închirierile Mele',
                  userName: 'Pinlend',
                  avatarUrl: _RentalsScreenState._avatarUrl,
                ),
              )
            else
              const SliverToBoxAdapter(
                child: SizedBox(height: LendTopBar.height),
              ),
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
                      if (snapshot.connectionState != ConnectionState.done) {
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
                          title: GeneratedLocalizations.of(
                            context,
                          ).couldNotLoadRentals,
                          body: GeneratedLocalizations.of(
                            context,
                          ).profileLoadErrorBody,
                          actionLabel: GeneratedLocalizations.of(context).retry,
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
                            (order) => _rentalItemFromOrder(
                              order,
                              _perspective,
                              GeneratedLocalizations.of(context),
                            ),
                          )
                          .toList();
                      final historyItems = orders
                          .where(_isHistoryOrder)
                          .map(
                            (order) => _historyItemFromOrder(
                              order,
                              GeneratedLocalizations.of(context),
                            ),
                          )
                          .toList();

                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _focusPendingRental(activeItems),
                      );

                      if (!_showHistory && activeItems.isEmpty) {
                        return _RentalsMessage(
                          icon: Icons.handshake_outlined,
                          title: GeneratedLocalizations.of(
                            context,
                          ).noActiveRentals,
                          body: _perspective == _RentalPerspective.renting
                              ? GeneratedLocalizations.of(
                                  context,
                                ).rentingEmptyBody
                              : GeneratedLocalizations.of(
                                  context,
                                ).lendingEmptyBody,
                        );
                      }

                      if (_showHistory && historyItems.isEmpty) {
                        return _RentalsMessage(
                          icon: Icons.history_rounded,
                          title: GeneratedLocalizations.of(
                            context,
                          ).noHistoryYet,
                          body: GeneratedLocalizations.of(
                            context,
                          ).completedRentalsBody,
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
                                itemKeys: _rentalKeys,
                                onScanReturn: _openReturnScanner,
                                onEditSchedule: _openScheduleEditor,
                                onAccept: _acceptRentalRequest,
                                onReject: _rejectRentalRequest,
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
    );

    if (!widget.showChrome) {
      return content;
    }

    return LendScreenFrame(backgroundColor: _background, child: content);
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
    }
  }

  Future<void> _acceptRentalRequest(_RentalItem item) async {
    await _updateRentalRequest(
      item,
      action: (token) =>
          _rentalOrdersApi.accept(accessToken: token, orderId: item.id),
      successMessage: GeneratedLocalizations.of(context).requestAccepted,
    );
  }

  Future<void> _rejectRentalRequest(_RentalItem item) async {
    await _updateRentalRequest(
      item,
      action: (token) =>
          _rentalOrdersApi.reject(accessToken: token, orderId: item.id),
      successMessage: GeneratedLocalizations.of(context).requestRejected,
    );
  }

  Future<void> _updateRentalRequest(
    _RentalItem item, {
    required Future<RentalOrder> Function(String token) action,
    required String successMessage,
  }) async {
    final strings = GeneratedLocalizations.of(context);
    try {
      final token = await AuthSessionStore.getToken();

      if (token == null) {
        throw RentalOrdersApiException(strings.signInRequired);
      }

      await action(token);

      if (!mounted) {
        return;
      }

      _reloadOrders();
      LendToast.info(context, message: successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }

      LendToast.info(context, message: error.toString());
    }
  }

  Future<void> _openScheduleEditor(_RentalItem item) async {
    final strings = GeneratedLocalizations.of(context);
    final pickupController = TextEditingController(text: item.pickupTime);
    final returnController = TextEditingController(text: item.returnTime);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var saving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickTime(TextEditingController controller) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
                initialEntryMode: TimePickerEntryMode.dial,
              );
              if (picked == null || !context.mounted) return;
              setModalState(() {
                controller.text = _formatTime(picked);
              });
            }

            Future<void> save() async {
              final pickupTime = pickupController.text.trim();
              final returnTime = returnController.text.trim();

              if (!_isValidTime(pickupTime) || !_isValidTime(returnTime)) {
                LendToast.info(context, message: strings.timeFormatHint);
                return;
              }

              setModalState(() {
                saving = true;
              });

              var shouldResetSaving = true;
              try {
                final token = await AuthSessionStore.getToken();

                if (token == null) {
                  throw RentalOrdersApiException(strings.signInRequired);
                }

                await _rentalOrdersApi.updateSchedule(
                  accessToken: token,
                  orderId: item.id,
                  pickupTime: pickupTime,
                  returnTime: returnTime,
                );

                if (!context.mounted || !mounted) {
                  return;
                }

                Navigator.of(context).pop();
                shouldResetSaving = false;
                _reloadOrders();
                LendToast.info(context, message: 'Program actualizat.');
              } catch (error) {
                if (!context.mounted) {
                  return;
                }

                LendToast.info(context, message: error.toString());
              } finally {
                if (shouldResetSaving && context.mounted) {
                  setModalState(() {
                    saving = false;
                  });
                }
              }
            }

            final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _RentalsScreenState._text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ScheduleTextField(
                          controller: pickupController,
                          label: 'Ridicare',
                          hint: '10:00',
                          onTap: () => pickTime(pickupController),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScheduleTextField(
                          controller: returnController,
                          label: 'Retur',
                          hint: '18:00',
                          onTap: () => pickTime(returnController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _RentalsScreenState._primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salveaza programul',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    pickupController.dispose();
    returnController.dispose();
  }

  static bool _isValidTime(String value) {
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ScheduleTextField extends StatelessWidget {
  const _ScheduleTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _RentalsScreenState._muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          showCursor: false,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: const Icon(Icons.schedule_rounded),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC3C6D1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC3C6D1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _RentalsScreenState._primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
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
  const _PerspectiveTabs({required this.selected, required this.onChanged});

  final _RentalPerspective selected;
  final ValueChanged<_RentalPerspective> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

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
                label: strings.iRent,
                selected: selected == _RentalPerspective.renting,
                onTap: () => onChanged(_RentalPerspective.renting),
              ),
            ),
            Expanded(
              child: _PerspectiveTab(
                icon: Icons.storefront_rounded,
                label: strings.fromMe,
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
    final strings = GeneratedLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDED9C8))),
      ),
      child: Row(
        children: [
          _RentalTab(
            label: strings.active,
            selected: !showHistory,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 32),
          _RentalTab(
            label: strings.history,
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
    required this.itemKeys,
    required this.onScanReturn,
    required this.onEditSchedule,
    required this.onAccept,
    required this.onReject,
  });

  final List<_RentalItem> items;
  final _RentalPerspective perspective;
  final Map<String, GlobalKey> itemKeys;
  final VoidCallback onScanReturn;
  final ValueChanged<_RentalItem> onEditSchedule;
  final ValueChanged<_RentalItem> onAccept;
  final ValueChanged<_RentalItem> onReject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;

        if (crossAxisCount == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _buildCard(items[index]),
                if (index < items.length - 1) const SizedBox(height: 20),
              ],
            ],
          );
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: perspective == _RentalPerspective.lending
                ? 512
                : 464,
          ),
          itemBuilder: (context, index) => _buildCard(items[index]),
        );
      },
    );
  }

  Widget _buildCard(_RentalItem item) {
    return _ActiveRentalCard(
      key: itemKeys[item.id],
      item: item,
      perspective: perspective,
      onScanReturn: onScanReturn,
      onEditSchedule: onEditSchedule,
      onAccept: onAccept,
      onReject: onReject,
    );
  }
}

class _ActiveRentalCard extends StatelessWidget {
  const _ActiveRentalCard({
    super.key,
    required this.item,
    required this.perspective,
    required this.onScanReturn,
    required this.onEditSchedule,
    required this.onAccept,
    required this.onReject,
  });

  final _RentalItem item;
  final _RentalPerspective perspective;
  final VoidCallback onScanReturn;
  final ValueChanged<_RentalItem> onEditSchedule;
  final ValueChanged<_RentalItem> onAccept;
  final ValueChanged<_RentalItem> onReject;

  @override
  Widget build(BuildContext context) {
    final expiring = item.status == _RentalStatus.expiring;
    final isPendingRequest = item.statusRaw == 'pending';
    final hasAuthorizedPayment =
        item.paymentStatus == 'authorized' || item.paymentStatus == 'captured';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 224,
          decoration: _rentalCardDecoration,
          clipBehavior: Clip.antiAlias,
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
                  text: isPendingRequest
                      ? 'Cerere'
                      : expiring
                      ? 'Expira azi'
                      : 'In curs',
                  color: expiring
                      ? _RentalsScreenState._error
                      : _RentalsScreenState._primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _rentalCardDecoration,
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
                        maxLines: 1,
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
                const SizedBox(height: 10),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: _RentalsScreenState._muted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.scheduleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _RentalsScreenState._muted,
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (perspective == _RentalPerspective.lending) ...[
                  if (isPendingRequest && hasAuthorizedPayment) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () => onReject(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _RentalsScreenState._error,
                                side: const BorderSide(
                                  color: _RentalsScreenState._error,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                GeneratedLocalizations.of(context).reject,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: FilledButton(
                              onPressed: () => onAccept(item),
                              style: FilledButton.styleFrom(
                                backgroundColor: _RentalsScreenState._primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                GeneratedLocalizations.of(context).accept,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else if (isPendingRequest) ...[
                    Text(
                      GeneratedLocalizations.of(
                        context,
                      ).waitingPaymentAuthorization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RentalsScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!isPendingRequest) ...[
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => onEditSchedule(item),
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: Text(
                          GeneratedLocalizations.of(context).editTime,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _RentalsScreenState._text,
                          side: const BorderSide(color: Color(0xFFC3C6D1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                if (!(perspective == _RentalPerspective.lending &&
                    isPendingRequest))
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed:
                          perspective == _RentalPerspective.renting &&
                              isPendingRequest
                          ? null
                          : () {
                              if (perspective == _RentalPerspective.lending) {
                                onScanReturn();
                                return;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReturnQrScreen(
                                    orderId: item.id,
                                    itemTitle: item.title,
                                    itemImageUrl: item.imageUrl,
                                    returnCode: 'borrowit:return:${item.id}',
                                  ),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _RentalsScreenState._primary,
                        disabledBackgroundColor: const Color(0xFFC3C6D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        perspective == _RentalPerspective.renting
                            ? isPendingRequest
                                  ? GeneratedLocalizations.of(
                                      context,
                                    ).waitingApproval
                                  : GeneratedLocalizations.of(
                                      context,
                                    ).completeReturn
                            : GeneratedLocalizations.of(context).scanReturnCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
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
                          GeneratedLocalizations.of(
                            context,
                          ).returnedSuccessfully,
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
    final strings = GeneratedLocalizations.of(context);
    final normalized = text.toLowerCase();

    if (normalized.contains('azi') || normalized.contains('today')) {
      return strings.expiresToday;
    }

    if (normalized.contains('curs') || normalized.contains('progress')) {
      return strings.inProgress;
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
              GeneratedLocalizations.of(context).verified,
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
    required this.scheduleText,
    required this.pickupTime,
    required this.returnTime,
    required this.imageUrl,
    required this.imageContentType,
    required this.imageType,
    required this.detailText,
    required this.statusRaw,
    required this.paymentStatus,
    required this.status,
  });

  final String id;
  final String title;
  final String dateText;
  final String scheduleText;
  final String pickupTime;
  final String returnTime;
  final String imageUrl;
  final String imageContentType;
  final String imageType;
  final String detailText;
  final String statusRaw;
  final String paymentStatus;
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
  address: '',
  latitude: null,
  longitude: null,
  pickupTime: '10:00',
  returnTime: '18:00',
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
