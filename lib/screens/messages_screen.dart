import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../services/auth_api.dart';
import '../services/messages_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../models/rental_mode.dart';
import '../widgets/lend_screen_frame.dart';
import 'rental_period_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const _blue = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  Future<List<MessageThreadSummary>>? _threads;
  final _authApi = AuthApi();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _threads = _loadThreads();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<MessageThreadSummary>> _loadThreads() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) return const [];
    final user = await _authApi.me(token);
    _currentUserId = user.id;
    return MessagesApi().findThreads(token);
  }

  @override
  Widget build(BuildContext context) {
    return LendScreenFrame(
      backgroundColor: _background,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('Mesaje'),
          backgroundColor: _background,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: FutureBuilder<List<MessageThreadSummary>>(
          future: _threads,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final threads = snapshot.data ?? const <MessageThreadSummary>[];
            if (threads.isEmpty) {
              return const Center(child: Text('Nu ai conversații încă.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 78),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductChatScreen(
                        productId: thread.productId,
                        productTitle: thread.productTitle,
                        ownerName: thread.participantName,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ConversationAvatar(
                          name: thread.participantName,
                          imageUrl: thread.participantAvatarUrl,
                          unread: thread.unreadCount > 0,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      thread.participantName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _threadTime(thread.latestCreatedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                thread.productTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                thread.latestSenderId == _currentUserId
                                    ? 'You: ${thread.latestMessage}'
                                    : thread.latestMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: thread.unreadCount > 0
                                      ? Colors.black87
                                      : Colors.grey.shade700,
                                  fontWeight: thread.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (thread.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.name,
    this.imageUrl,
    required this.unread,
  });

  final String name;
  final String? imageUrl;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: unread ? const Color(0xFF30578F) : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFDCE8FA),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF30578F),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}

String _threadTime(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.userId,
    required this.productTitle,
    this.productImageUrl,
    this.product,
    required this.onUpdate,
    required this.onCheckout,
  });

  final RentalOffer offer;
  final String userId;
  final String productTitle;
  final String? productImageUrl;
  final LendProduct? product;
  final Future<void> Function(RentalOffer offer, bool accept) onUpdate;
  final Future<void> Function(RentalOffer offer) onCheckout;

  @override
  Widget build(BuildContext context) {
    final mine = offer.senderId == userId;
    final pending = offer.status == 'pending';
    final accepted = offer.status == 'accepted';
    final color = accepted
        ? Colors.green
        : offer.status == 'rejected'
        ? Colors.red
        : const Color(0xFF30578F);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: productImageUrl == null
                      ? const ColoredBox(
                          color: Color(0xFFE2EBFA),
                          child: Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFF30578F),
                          ),
                        )
                      : Image.network(
                          productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE2EBFA),
                            child: Icon(
                              Icons.home_work_outlined,
                              color: Color(0xFF30578F),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mine ? 'Oferta ta' : 'Ofertă primită',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${offer.amount} RON',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            productTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _offerStatus(offer.status),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _OfferInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Perioadă',
                  value:
                      '${_shortDate(offer.startDate)} – ${_shortDate(offer.endDate)}',
                ),
                const SizedBox(height: 8),
                _OfferInfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Tip închiriere',
                  value: _rentalModeLabel(offer.rentalMode),
                ),
                if (product?.city.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _OfferInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Locație',
                    value: product!.city,
                  ),
                ],
              ],
            ),
          ),
          if (product?.description.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              product!.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (!mine && pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onUpdate(offer, false),
                    child: const Text('Refuză'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => onUpdate(offer, true),
                    child: const Text('Acceptă'),
                  ),
                ),
              ],
            ),
          ],
          if (mine && accepted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onCheckout(offer),
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Continuă către plată'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferInfoRow extends StatelessWidget {
  const _OfferInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.startsWith('Perioad')
        ? 'Perioad\u0103'
        : label.startsWith('Tip ')
        ? 'Tip \u00eenchiriere'
        : label.startsWith('Loca')
        ? 'Loca\u021bie'
        : label;
    final dateMatch = RegExp(
      r'(\d{2}\.\d{2}\.\d{4}).*?(\d{2}\.\d{2}\.\d{4})',
    ).firstMatch(value);
    final normalizedDate = dateMatch == null
        ? value
        : '${dateMatch.group(1)} – ${dateMatch.group(2)}';
    final displayValue = value.replaceAll('â€“', '–');

    final cleanDate = dateMatch == null
        ? displayValue
        : normalizedDate.replaceAll(RegExp(r'[^0-9. -]'), ' ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF30578F)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayLabel,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                cleanDate,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _offerStatus(String status) {
  switch (status) {
    case 'accepted':
      return 'Acceptată';
    case 'rejected':
      return 'Refuzată';
    case 'expired':
      return 'Expirată';
    default:
      return 'În așteptarea răspunsului';
  }
}

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String _rentalModeLabel(String mode) {
  switch (mode) {
    case 'hour':
      return 'Pe oră';
    case 'month':
      return 'Pe lună';
    default:
      return 'Pe zi';
  }
}

class _OfferDraft {
  const _OfferDraft({
    required this.rentalMode,
    required this.startDate,
    required this.endDate,
    required this.amount,
  });
  final String rentalMode;
  final DateTime startDate;
  final DateTime endDate;
  final int amount;
}

class _OfferDraftSheet extends StatefulWidget {
  const _OfferDraftSheet({
    required this.modes,
    required this.today,
    required this.product,
    required this.amountController,
  });
  final List<String> modes;
  final DateTime today;
  final LendProduct product;
  final TextEditingController amountController;

  @override
  State<_OfferDraftSheet> createState() => _OfferDraftSheetState();
}

class _OfferDraftSheetState extends State<_OfferDraftSheet> {
  int _step = 0;
  bool _ignoreInitialCalendarChange = true;
  late String _mode = widget.modes.first;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ignoreInitialCalendarChange = false);
    });
  }

  DateTime get _firstDate => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day,
  ).add(const Duration(days: 1));

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1 && _start != null && _end != null) {
      setState(() => _step = 2);
    } else if (_step == 2 &&
        _end != null &&
        widget.amountController.text.trim().isNotEmpty) {
      final amount = int.tryParse(widget.amountController.text.trim());
      if (amount != null && amount > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(
          context,
          _OfferDraft(
            rentalMode: _mode,
            startDate: _start!,
            endDate: _end!,
            amount: amount,
          ),
        );
      }
    }
  }

  int get _normalPrice {
    final days = _start == null || _end == null
        ? 1
        : _end!.difference(_start!).inDays.clamp(1, 365);
    if (_mode == 'month')
      return widget.product.pricePerMonth ?? days * widget.product.pricePerDay;
    return days * widget.product.pricePerDay;
  }

  void _selectDate(DateTime date) {
    if (_ignoreInitialCalendarChange) return;
    if (_start == null) {
      setState(() => _start = date);
      return;
    }
    if (date.isAfter(_start!)) {
      setState(() => _end = date);
    } else {
      setState(() {
        _start = date;
        _end = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 0
        ? 'Alege modul'
        : _step == 1
        ? (_start == null ? 'Alege începutul' : 'Alege sfârșitul')
        : 'Verifică oferta';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trimite o ofertă',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anulează'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_step == 0)
                ...widget.modes.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _mode = mode;
                          _step = 1;
                        }),
                        icon: Icon(
                          mode == 'month'
                              ? Icons.calendar_month_outlined
                              : mode == 'hour'
                              ? Icons.schedule
                              : Icons.today,
                        ),
                        label: Text(_rentalModeLabel(mode)),
                      ),
                    ),
                  ),
                ),
              if (_step == 1)
                _OfferRangeCalendar(
                  firstDate: _firstDate,
                  lastDate: DateTime(widget.today.year + 2),
                  startDate: _start,
                  endDate: _end,
                  onDateSelected: _selectDate,
                ),
              if (_step == 2) ...[
                if (_mode == 'month')
                  Text(
                    'Perioada: ${_shortDate(_start!)} – ${_shortDate(_end!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preț normal pentru perioada aleasă',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$_normalPrice RON',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF30578F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Suma propusă de tine',
                    hintText: 'Introdu suma',
                    suffixText: 'RON',
                  ),
                ),
              ],
              if (_step > 0)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _step--;
                        if (_step == 1) _end = null;
                      }),
                      child: const Text('Înapoi'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _step == 1 && (_start == null || _end == null)
                          ? null
                          : _next,
                      child: Text(_step == 2 ? 'Trimite oferta' : 'Continuă'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferRangeCalendar extends StatefulWidget {
  const _OfferRangeCalendar({
    required this.firstDate,
    required this.lastDate,
    required this.startDate,
    required this.endDate,
    required this.onDateSelected,
  });
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_OfferRangeCalendar> createState() => _OfferRangeCalendarState();
}

class _OfferRangeCalendarState extends State<_OfferRangeCalendar> {
  late DateTime _month = DateTime(
    (widget.startDate ?? widget.firstDate).year,
    (widget.startDate ?? widget.firstDate).month,
  );
  static const _blue = Color(0xFF30578F);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = List<DateTime?>.filled(firstWeekday - 1, null, growable: true)
      ..addAll(
        List.generate(
          daysInMonth,
          (index) => DateTime(_month.year, _month.month, index + 1),
        ),
      );
    final canPrevious = _month.isAfter(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
    final canNext = _month.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canPrevious
                  ? () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(_month),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              onPressed: canNext
                  ? () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            if (date == null) return const SizedBox.shrink();
            final disabled =
                date.isBefore(widget.firstDate) ||
                date.isAfter(widget.lastDate);
            final isStart =
                widget.startDate != null && _sameDay(date, widget.startDate!);
            final isEnd =
                widget.endDate != null && _sameDay(date, widget.endDate!);
            final inRange =
                widget.startDate != null &&
                widget.endDate != null &&
                !date.isBefore(widget.startDate!) &&
                !date.isAfter(widget.endDate!);
            return GestureDetector(
              onTap: disabled ? null : () => widget.onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: inRange && !isStart && !isEnd
                      ? const Color(0xFFDCE8FA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isStart ? const Radius.circular(22) : Radius.zero,
                    right: isEnd ? const Radius.circular(22) : Radius.zero,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isStart || isEnd ? _blue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: disabled
                            ? Colors.grey.shade300
                            : isStart || isEnd
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: isStart || isEnd
                            ? FontWeight.w800
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _monthLabel(DateTime date) {
  const months = [
    'ianuarie',
    'februarie',
    'martie',
    'aprilie',
    'mai',
    'iunie',
    'iulie',
    'august',
    'septembrie',
    'octombrie',
    'noiembrie',
    'decembrie',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

class ProductChatScreen extends StatefulWidget {
  const ProductChatScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.ownerName,
  });

  final String productId;
  final String productTitle;
  final String ownerName;

  @override
  State<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  static const _blue = Color(0xFF30578F);
  final _api = MessagesApi();
  final _authApi = AuthApi();
  final _composer = TextEditingController();
  List<Message> _messages = const [];
  List<RentalOffer> _offers = const [];
  String? _token;
  String? _userId;
  socket_io.Socket? _socket;
  bool _loading = true;
  bool _sending = false;
  bool _isOwner = false;
  String? _productImageUrl;
  LendProduct? _chatProduct;
  String _chatParticipantName = '';
  String? _chatParticipantAvatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) return;
    try {
      final user = await _authApi.me(token);
      final thread = await _api.getForProduct(
        accessToken: token,
        productId: widget.productId,
      );
      if (!mounted) return;
      setState(() {
        _token = token;
        _userId = user.id;
        _messages = thread.messages;
        _offers = thread.offers;
        _isOwner = thread.ownerId == user.id;
        _chatParticipantName = thread.participantName.isEmpty
            ? widget.ownerName
            : thread.participantName;
        _chatParticipantAvatarUrl = thread.participantAvatarUrl;
        _loading = false;
      });
      unawaited(_loadProductImage());
      final socket = _api.connectSocket(token);
      _socket = socket;
      socket.onConnect((_) {
        socket.emit('conversation.join', {'productId': widget.productId});
      });
      socket.on('message.new', (data) {
        if (data is! Map) return;
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        if (!mounted || _messages.any((item) => item.id == message.id)) return;
        setState(() => _messages = [..._messages, message]);
      });
      socket.on('offer.updated', (data) {
        if (data is! Map) return;
        final offer = RentalOffer.fromJson(Map<String, dynamic>.from(data));
        if (!mounted) return;
        _upsertOffer(offer);
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProductImage() async {
    try {
      final products = await ProductsApi().findAll();
      final product = products
          .where((item) => item.id == widget.productId)
          .firstOrNull;
      if (!mounted || product == null) return;
      setState(() {
        _chatProduct = product;
        _productImageUrl = product.imageUrl.isEmpty ? null : product.imageUrl;
      });
    } catch (_) {
      // The conversation remains usable with the generic fallback icon.
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _token == null || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _api.send(
        accessToken: _token!,
        productId: widget.productId,
        body: body,
      );
      if (!mounted) return;
      _composer.clear();
      if (!_messages.any((item) => item.id == message.id)) {
        setState(() => _messages = [..._messages, message]);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendOffer() async {
    final products = await ProductsApi().findAll();
    final productMatches = products
        .where((item) => item.id == widget.productId)
        .toList();
    final product = productMatches.isEmpty ? null : productMatches.first;
    final modes =
        product?.rentalModes
            .where((mode) => const ['hour', 'day', 'month'].contains(mode))
            .toList() ??
        const <String>[];
    if (modes.isEmpty || !mounted) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Acest anunț nu are un mod de închiriere disponibil.',
            ),
          ),
        );
      return;
    }
    final today = DateTime.now();
    final amountController = TextEditingController();
    final draft = await showModalBottomSheet<_OfferDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _OfferDraftSheet(
        modes: modes,
        today: today,
        product: product!,
        amountController: amountController,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => amountController.dispose(),
    );
    if (draft == null || !mounted) return;
    final start = draft.startDate;
    final end = draft.endDate;
    final mode = draft.rentalMode;
    try {
      final availability = await RentalOrdersApi().getAvailability(
        productId: widget.productId,
        from: start,
        to: end,
      );
      final occupied = <String>[];
      for (
        var date = DateTime(start.year, start.month, start.day);
        date.isBefore(end);
        date = date.add(const Duration(days: 1))
      ) {
        final key =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (availability.unavailableDates.contains(key)) occupied.add(key);
      }
      if (occupied.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perioada selectată este deja ocupată. Alege alte date.',
            ),
          ),
        );
        return;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nu am putut verifica disponibilitatea: $error'),
        ),
      );
      return;
    }
    if (!mounted) return;
    /*
    final amountController = TextEditingController();
    var mode = modes.first;
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trimite o ofertă'),
        content: StatefulBuilder(builder: (context, setDialogState) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_shortDate(start)} – ${_shortDate(end)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          DropdownButtonFormField<String>(initialValue: mode, decoration: const InputDecoration(labelText: 'Mod închiriere'), items: modes.map((item) => DropdownMenuItem(value: item, child: Text(_rentalModeLabel(item)))).toList(), onChanged: (value) => setDialogState(() => mode = value ?? modes.first)),
          TextField(controller: amountController, keyboardType: TextInputType.number, autofocus: true, decoration: const InputDecoration(labelText: 'Suma propusă (RON)', suffixText: 'RON')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(amountController.text.trim())), child: const Text('Trimite')),
        ],
      ),
    );
    amountController.dispose();
    */
    final amount = draft.amount;
    if (amount <= 0 || _token == null) return;
    try {
      final offer = await _api.createOffer(
        accessToken: _token!,
        productId: widget.productId,
        amount: amount,
        startDate: start,
        endDate: end,
        rentalMode: mode,
      );
      if (mounted) _upsertOffer(offer);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _updateOffer(RentalOffer offer, bool accept) async {
    if (_token == null) return;
    try {
      final updated = await _api.updateOffer(
        accessToken: _token!,
        offerId: offer.id,
        accept: accept,
      );
      if (mounted) _upsertOffer(updated);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _upsertOffer(RentalOffer offer) {
    if (!mounted) return;
    setState(() {
      final index = _offers.indexWhere((item) => item.id == offer.id);
      if (index == -1) {
        _offers = [..._offers, offer];
      } else {
        final updated = [..._offers];
        updated[index] = offer;
        _offers = updated;
      }
    });
  }

  Future<void> _checkoutOffer(RentalOffer offer) async {
    if (_token == null) return;
    try {
      final claimed = await _api.claimOffer(
        accessToken: _token!,
        offerId: offer.id,
      );
      if (mounted) _upsertOffer(claimed);
      final products = await ProductsApi().findAll();
      final matches = products
          .where((item) => item.id == widget.productId)
          .toList();
      final product = matches.isEmpty ? null : matches.first;
      if (product == null || !mounted) return;
      final rentalMode = RentalMode.values.firstWhere(
        (item) => item.name == offer.rentalMode,
        orElse: () => RentalMode.day,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RentalPeriodScreen(
            product: product,
            rentalMode: rentalMode,
            initialStartDate: offer.startDate,
            initialEndDate: offer.endDate,
            negotiatedSubtotal: offer.amount,
            lockSelection: true,
          ),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerImageUrl = _chatParticipantAvatarUrl;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFDCE8FA),
              backgroundImage: headerImageUrl == null
                  ? null
                  : NetworkImage(headerImageUrl),
              child: headerImageUrl == null
                  ? Text(
                      (_chatParticipantName.isEmpty
                              ? widget.ownerName
                              : _chatParticipantName)
                          .trim()
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _chatParticipantName.isEmpty
                        ? widget.ownerName
                        : _chatParticipantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _productImageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFE2EBFA),
                            child: Icon(Icons.home_work_outlined, color: _blue),
                          )
                        : Image.network(
                            _productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFE2EBFA),
                              child: Icon(
                                Icons.home_work_outlined,
                                color: _blue,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Conversație despre acest anunț',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + _offers.length,
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return _OfferCard(
                          offer: _offers[index - _messages.length],
                          userId: _userId ?? '',
                          productTitle: widget.productTitle,
                          productImageUrl: _productImageUrl,
                          product: _chatProduct,
                          onUpdate: _updateOffer,
                          onCheckout: _checkoutOffer,
                        );
                      }
                      final message = _messages[index];
                      final mine = message.senderId == _userId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: mine ? _blue : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.body,
                            style: TextStyle(
                              color: mine ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Scrie un mesaj...',
                      ),
                    ),
                  ),
                  if (!_isOwner)
                    IconButton(
                      tooltip: 'Trimite ofertă',
                      onPressed: _sending ? null : _sendOffer,
                      icon: const Icon(
                        Icons.local_offer_outlined,
                        color: _blue,
                      ),
                    ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: _blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
