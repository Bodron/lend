import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../services/auth_api.dart';
import '../services/messages_api.dart';
import '../services/products_api.dart';
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
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Text(
                                    _threadTime(thread.latestCreatedAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                thread.productTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                thread.latestMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: thread.unreadCount > 0 ? Colors.black87 : Colors.grey.shade700,
                                  fontWeight: thread.unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
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
                            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)),
                            child: Text('${thread.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
  const _ConversationAvatar({required this.name, this.imageUrl, required this.unread});

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
        border: Border.all(color: unread ? const Color(0xFF30578F) : Colors.transparent, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFDCE8FA),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null ? Text(initial, style: const TextStyle(color: Color(0xFF30578F), fontSize: 20, fontWeight: FontWeight.w800)) : null,
      ),
    );
  }
}

String _threadTime(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  if (local.year == now.year && local.month == now.month && local.day == now.day) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.userId, required this.onUpdate, required this.onCheckout});

  final RentalOffer offer;
  final String userId;
  final Future<void> Function(RentalOffer offer, bool accept) onUpdate;
  final Future<void> Function(RentalOffer offer) onCheckout;

  @override
  Widget build(BuildContext context) {
    final mine = offer.senderId == userId;
    final pending = offer.status == 'pending';
    final accepted = offer.status == 'accepted';
    final color = accepted ? Colors.green : offer.status == 'rejected' ? Colors.red : const Color(0xFF30578F);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.local_offer_outlined, size: 19, color: color), const SizedBox(width: 8), Text(mine ? 'Oferta ta' : 'Ofertă primită', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${offer.amount} RON', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color))]),
        const SizedBox(height: 6),
        Text(_offerStatus(offer.status), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        if (!mine && pending) ...[
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () => onUpdate(offer, false), child: const Text('Refuză'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => onUpdate(offer, true), child: const Text('Acceptă')))]),
        ],
        if (mine && accepted) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => onCheckout(offer), icon: const Icon(Icons.payment_outlined), label: const Text('Continuă către plată'))),
        ],
      ]),
    );
  }
}

String _offerStatus(String status) {
  switch (status) {
    case 'accepted': return 'Acceptată';
    case 'rejected': return 'Refuzată';
    case 'expired': return 'Expirată';
    default: return 'În așteptarea răspunsului';
  }
}

String _shortDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String _rentalModeLabel(String mode) {
  switch (mode) {
    case 'hour': return 'Pe oră';
    case 'month': return 'Pe lună';
    default: return 'Pe zi';
  }
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
        _loading = false;
      });
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
        setState(() {
          _offers = [..._offers.where((item) => item.id != offer.id), offer];
        });
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    final productMatches = products.where((item) => item.id == widget.productId).toList();
    final product = productMatches.isEmpty ? null : productMatches.first;
    final modes = product?.rentalModes.where((mode) => const ['hour', 'day', 'month'].contains(mode)).toList() ?? const <String>[];
    if (modes.isEmpty || !mounted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acest anunț nu are un mod de închiriere disponibil.')));
      return;
    }
    final today = DateTime.now();
    final start = await showDatePicker(context: context, firstDate: today, lastDate: DateTime(today.year + 2), initialDate: today.add(const Duration(days: 1)));
    if (start == null || !mounted) return;
    final end = await showDatePicker(context: context, firstDate: start.add(const Duration(days: 1)), lastDate: DateTime(today.year + 2), initialDate: start.add(const Duration(days: 3)));
    if (end == null || !mounted) return;
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
    if (amount == null || amount <= 0 || _token == null) return;
    try {
      final offer = await _api.createOffer(accessToken: _token!, productId: widget.productId, amount: amount, startDate: start, endDate: end, rentalMode: mode);
      if (mounted) setState(() => _offers = [..._offers, offer]);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _updateOffer(RentalOffer offer, bool accept) async {
    if (_token == null) return;
    try {
      final updated = await _api.updateOffer(accessToken: _token!, offerId: offer.id, accept: accept);
      if (mounted) setState(() => _offers = [..._offers.where((item) => item.id != updated.id), updated]);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _checkoutOffer(RentalOffer offer) async {
    if (_token == null) return;
    try {
      final products = await ProductsApi().findAll();
      final matches = products.where((item) => item.id == widget.productId).toList();
      final product = matches.isEmpty ? null : matches.first;
      if (product == null || !mounted) return;
      final rentalMode = RentalMode.values.firstWhere((item) => item.name == offer.rentalMode, orElse: () => RentalMode.day);
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RentalPeriodScreen(product: product, rentalMode: rentalMode, initialStartDate: offer.startDate, initialEndDate: offer.endDate, negotiatedSubtotal: offer.amount)));
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ownerName, style: const TextStyle(fontSize: 17)),
            Text(widget.productTitle, style: const TextStyle(fontSize: 12)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE2EBFA), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_work_outlined, color: _blue)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.productTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), const Text('Conversație despre acest anunț', style: TextStyle(fontSize: 12, color: Colors.black54))])),
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
                        return _OfferCard(offer: _offers[index - _messages.length], userId: _userId ?? '', onUpdate: _updateOffer, onCheckout: _checkoutOffer);
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
                      icon: const Icon(Icons.local_offer_outlined, color: _blue),
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
