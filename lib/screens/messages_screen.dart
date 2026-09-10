import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../services/auth_api.dart';
import '../services/messages_api.dart';
import '../widgets/lend_screen_frame.dart';

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
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    thread.ownerName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${thread.productTitle}\n${thread.latestMessage}',
                  ),
                  isThreeLine: true,
                  trailing: thread.unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: _blue,
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductChatScreen(
                        productId: thread.productId,
                        productTitle: thread.productTitle,
                        ownerName: thread.ownerName,
                      ),
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
  String? _token;
  String? _userId;
  socket_io.Socket? _socket;
  bool _loading = true;
  bool _sending = false;

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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _token == null || _sending) return;
    setState(() => _sending = true);
    try {
      final socket = _socket;
      if (socket?.connected == true) {
        socket!.emit('message.send', {
          'productId': widget.productId,
          'body': body,
        });
        _composer.clear();
        return;
      }

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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
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
