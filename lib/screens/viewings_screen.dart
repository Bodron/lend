import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../services/auth_api.dart';
import '../services/payments_api.dart';
import '../services/products_api.dart';
import '../services/viewings_api.dart';
import '../services/verification_api.dart';
import 'transaction_verification_screen.dart';

class ViewingsScreen extends StatefulWidget {
  const ViewingsScreen({super.key, this.product});
  final LendProduct? product;

  static Future<bool> showRequestSheet(
    BuildContext context,
    LendProduct product,
  ) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => _ViewingRequestSheet(product: product),
        ) ??
        false;
  }

  @override
  State<ViewingsScreen> createState() => _ViewingsScreenState();
}

class _ViewingsScreenState extends State<ViewingsScreen> {
  final _api = ViewingsApi();
  bool _busy = false;
  String? _error;
  List<Viewing> _items = const [];
  String? _userId;

  bool get _english => Localizations.localeOf(context).languageCode == 'en';
  String _label(String ro, String en) => _english ? en : ro;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<String> _token() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) throw Exception('Sign in required');
    return token;
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await _token();
      final user = await AuthApi().me(token);
      final items = await _api.mine(token);
      if (!mounted) return;
      setState(() {
        _userId = user.id;
        _items = items;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    final product = widget.product;
    if (product == null) return;
    final created = await ViewingsScreen.showRequestSheet(context, product);
    if (created && mounted) await _refresh();
  }

  Future<bool> _ensureIdentityVerified() async {
    final token = await _token();
    if ((await VerificationApi().status(token)).identityVerified) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TransactionVerificationScreen(forViewing: true),
      ),
    );
    if (verified != true) {
      return false;
    }
    return (await VerificationApi().status(token)).identityVerified;
  }

  Future<void> _action(Viewing item, String action) => _run(() async {
    await _api.action(await _token(), item.id, action);
    await _refresh();
  });

  Future<void> _pay(Viewing item) => _run(() async {
    final token = await _token();
    final config = await PaymentsApi().getConfig();
    if (config.publishableKey.isEmpty) {
      throw Exception('Stripe is not configured');
    }
    Stripe.publishableKey = config.publishableKey;
    await Stripe.instance.applySettings();
    final secret = await _api.startPayment(token, item.id);
    if (secret.isNotEmpty) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: secret,
          merchantDisplayName: 'Lend',
          style: ThemeMode.system,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'RO',
            currencyCode: 'RON',
            testEnv: true,
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    }
    await _api.confirmPayment(token, item.id);
    try {
      if (mounted && await _ensureIdentityVerified()) {
        await _api.action(token, item.id, 'identity-confirmed');
      }
    } finally {
      await _refresh();
    }
  });

  Future<void> _verify(Viewing item) => _run(() async {
    if (!await _ensureIdentityVerified()) return;
    await _api.action(await _token(), item.id, 'identity-confirmed');
    await _refresh();
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _status(String status) => switch (status) {
    'requested' => _label('In asteptarea proprietarului', 'Waiting for owner'),
    'awaiting_payment' => _label(
      'Acceptata, asteapta plata',
      'Accepted, awaiting payment',
    ),
    'awaiting_verification' => _label(
      'Platita, asteapta verificarea ambelor persoane',
      'Paid, awaiting both identity checks',
    ),
    'refund_pending' => _label('Rambursare in curs', 'Refund in progress'),
    'confirmed' => _label('Confirmata', 'Confirmed'),
    'rejected' => _label('Respinsa', 'Declined'),
    'cancelled' => _label('Anulata', 'Cancelled'),
    'completed' => _label('Finalizata', 'Completed'),
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final items = product == null
        ? _items
        : _items.where((item) => item.productId == product.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(_label('Vizionari', 'Viewings'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (product != null) ...[
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                product.viewingPriceRon == 0
                    ? _label('Vizionare gratuita', 'Free viewing')
                    : _label(
                        'Vizionare: ${product.viewingPriceRon} RON + comision 5%. Platesti dupa acceptare, apoi va verificati amandoi identitatea.',
                        'Viewing: ${product.viewingPriceRon} RON + 5% service fee. Pay after acceptance, then both participants verify identity.',
                      ),
              ),
              if (product.viewingPriceRon > 0)
                Text(
                  _label(
                    'Daca proprietarul anuleaza, primesti rambursarea. Dupa confirmarea vizionarii, contacteaza suportul pentru anulare.',
                    'If the owner cancels, you receive a refund. After the viewing is confirmed, contact support to cancel.',
                  ),
                ),
              if (product.viewingPriceRon > 0)
                Text(
                  _label(
                    'Dupa plata aveti 48 de ore sa verificati identitatea, cel tarziu pana la ora vizionarii. Daca nu finalizati, plata este rambursata.',
                    'After payment, you have 48 hours to verify identity, or until the viewing starts. Otherwise the payment is refunded.',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _request,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _label('Propune data si ora', 'Propose date and time'),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (items.isEmpty && !_busy)
              Text(
                _label(
                  'Nu exista vizionari programate.',
                  'No viewings scheduled.',
                ),
              ),
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_userId == item.ownerId) Text(item.visitorName),
                      Text(
                        '${item.startsAt.day.toString().padLeft(2, '0')}.${item.startsAt.month.toString().padLeft(2, '0')}.${item.startsAt.year}  ${item.startsAt.hour.toString().padLeft(2, '0')}:${item.startsAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_status(item.status)),
                      if (item.refundStatus != null)
                        Text(
                          _label(
                            'Rambursare: ${item.refundStatus}',
                            'Refund: ${item.refundStatus}',
                          ),
                        ),
                      Text(
                        item.priceRon == 0
                            ? _label('Gratuit', 'Free')
                            : _label(
                                '${item.priceRon} RON + ${item.serviceFeeRon} RON comision = ${item.totalRon} RON',
                                '${item.priceRon} RON + ${item.serviceFeeRon} RON fee = ${item.totalRon} RON',
                              ),
                      ),
                      if (_userId == item.ownerId && item.status == 'requested')
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _action(item, 'accept'),
                              child: Text(_label('Accepta', 'Accept')),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _action(item, 'reject'),
                              child: Text(_label('Respinge', 'Decline')),
                            ),
                          ],
                        ),
                      if (_userId == item.visitorId &&
                          item.status == 'awaiting_payment')
                        FilledButton(
                          onPressed: _busy ? null : () => _pay(item),
                          child: Text(
                            _label('Plateste vizionarea', 'Pay for viewing'),
                          ),
                        ),
                      if (item.status == 'awaiting_verification')
                        FilledButton.icon(
                          onPressed: _busy ? null : () => _verify(item),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            _label('Verifica identitatea', 'Verify identity'),
                          ),
                        ),
                      if (_userId == item.ownerId &&
                          (item.status == 'confirmed' ||
                              (item.status == 'completed' &&
                                  item.priceRon > 0 &&
                                  item.hasCommission &&
                                  item.stripeTransferId == null)) &&
                          !item.startsAt.isAfter(DateTime.now()))
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _action(item, 'complete'),
                          child: Text(
                            _label('Marcheaza finalizata', 'Mark completed'),
                          ),
                        ),
                      if (item.status == 'requested' ||
                          item.status == 'awaiting_payment' ||
                          (item.status == 'awaiting_verification' &&
                              item.startsAt.isAfter(DateTime.now())) ||
                          (item.status == 'confirmed' &&
                              item.startsAt.isAfter(DateTime.now()) &&
                              (item.priceRon == 0 || _userId == item.ownerId)))
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _action(item, 'cancel'),
                          child: Text(_label('Anuleaza', 'Cancel')),
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

class _ViewingRequestSheet extends StatefulWidget {
  const _ViewingRequestSheet({required this.product});

  final LendProduct product;

  @override
  State<_ViewingRequestSheet> createState() => _ViewingRequestSheetState();
}

class _ViewingRequestSheetState extends State<_ViewingRequestSheet> {
  late DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);
  bool _submitting = false;
  String? _error;

  bool get _english => Localizations.localeOf(context).languageCode == 'en';
  String _label(String ro, String en) => _english ? en : ro;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(hours: 1));
    final lastDate = now.add(const Duration(days: 90));
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF5F5F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ViewingCalendarSheet(
        initialDate: _date,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
    if (date != null && mounted) {
      setState(() => _date = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null && mounted) {
      setState(() => _time = time);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final startsAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (startsAt.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      setState(
        () => _error = _label(
          'Alege o ora cu cel putin o ora in viitor.',
          'Choose a time at least one hour from now.',
        ),
      );
      return;
    }
    if (startsAt.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      setState(
        () => _error = _label(
          'Alege o data in urmatoarele 90 de zile.',
          'Choose a date within the next 90 days.',
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) {
        throw Exception(
          _label(
            'Autentifica-te pentru a cere o vizionare.',
            'Sign in to request a viewing.',
          ),
        );
      }
      await ViewingsApi().request(token, widget.product.id, startsAt);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final localizations = MaterialLocalizations.of(context);
    final price = widget.product.viewingPriceRon;
    final fee = (price * 0.05).round();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label('Programeaza o vizionare', 'Schedule a viewing'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price == 0
                                ? _label('Gratuit', 'Free')
                                : '$price + $fee = ${price + fee} RON',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            price == 0
                                ? _label(
                                    'Proprietarul iti confirma vizionarea.',
                                    'The owner confirms your viewing.',
                                  )
                                : _label(
                                    'Pretul include comisionul de 5%. Platesti dupa acceptare, apoi va verificati identitatea.',
                                    'The total includes a 5% fee. Pay after acceptance, then both participants verify identity.',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _label('Cand vrei sa mergi?', 'When would you like to visit?'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _selectDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(localizations.formatMediumDate(_date)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _selectTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(localizations.formatTimeOfDay(_time)),
            ),
            const SizedBox(height: 12),
            Text(
              _label(
                'Ora propusa este trimisa proprietarului pentru confirmare.',
                'The proposed time is sent to the owner for confirmation.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (price > 0) ...[
              const SizedBox(height: 8),
              Text(
                _label(
                  'Aveti 48 de ore dupa plata pentru verificarea ambelor persoane, cel tarziu pana la ora vizionarii. Daca verificarea nu se finalizeaza, suma este rambursata.',
                  'Both people must verify within 48 hours of payment, or before the viewing starts. If verification is not completed, the payment is refunded.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _label(
                  'Daca proprietarul anuleaza, vei primi rambursarea.',
                  'If the owner cancels, you will receive a refund.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _label(
                  'Daca anulezi dupa plata, contacteaza suportul.',
                  'If you cancel after payment, contact support.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_label('Trimite cererea', 'Send request')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewingCalendarSheet extends StatefulWidget {
  const _ViewingCalendarSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_ViewingCalendarSheet> createState() => _ViewingCalendarSheetState();
}

class _ViewingCalendarSheetState extends State<_ViewingCalendarSheet> {
  static const _primary = Color(0xFF30578F);
  static const _text = Color(0xFF1B1B1B);
  static const _outline = Color(0xFFC3C6D1);

  late DateTime _visibleMonth = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
  );

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _available(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(_dateOnly(widget.firstDate)) &&
        !day.isAfter(_dateOnly(widget.lastDate));
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final localizations = MaterialLocalizations.of(context);
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final gridStart = firstDay.subtract(
      Duration(days: firstDay.weekday - DateTime.monday),
    );
    final days = List.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    final canGoBack = _visibleMonth.isAfter(firstMonth);
    final canGoForward = _visibleMonth.isBefore(lastMonth);
    final weekdayLabels = english
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                english ? 'Choose the viewing date' : 'Alege data vizionarii',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _outline.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations.formatMonthYear(_visibleMonth),
                              style: const TextStyle(
                                color: _text,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: canGoBack
                                ? () => _changeMonth(-1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            onPressed: canGoForward
                                ? () => _changeMonth(1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          for (final label in weekdayLabels)
                            Expanded(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF737781),
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        itemCount: days.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                            ),
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final inMonth = day.month == _visibleMonth.month;
                          final available = inMonth && _available(day);
                          final selected =
                              inMonth && _sameDay(day, widget.initialDate);
                          final color = !inMonth
                              ? const Color(0x55737781)
                              : !available
                              ? const Color(0x88737781)
                              : selected
                              ? Colors.white
                              : _text;
                          return InkWell(
                            onTap: available
                                ? () => Navigator.of(context).pop(day)
                                : null,
                            borderRadius: BorderRadius.circular(999),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _primary
                                      : !available && inMonth
                                      ? const Color(0xFFE7E7E9)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: inMonth ? 14 : 12,
                                    fontWeight: inMonth
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    decoration: !available && inMonth
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
