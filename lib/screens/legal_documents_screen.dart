import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/legal_api.dart';

class LegalGate extends StatefulWidget {
  const LegalGate({super.key, required this.child});

  final Widget child;

  @override
  State<LegalGate> createState() => _LegalGateState();
}

class _LegalGateState extends State<LegalGate> {
  final _api = LegalApi();
  late Future<LegalAcceptanceStatus> _status = _load();

  Future<LegalAcceptanceStatus> _load() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) throw StateError('Autentificarea este necesară.');
    return _api.status(token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LegalAcceptanceStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nu am putut verifica acceptarea documentelor.'),
                  TextButton(
                    onPressed: () => setState(() => _status = _load()),
                    child: const Text('Încearcă din nou'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.current) return widget.child;
        return LegalDocumentsScreen(
          requireAcceptance: true,
          onAccepted: () => setState(() => _status = _load()),
        );
      },
    );
  }
}

class LegalDocumentsScreen extends StatefulWidget {
  const LegalDocumentsScreen({
    super.key,
    this.requireAcceptance = false,
    this.onAccepted,
  });

  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen> {
  final _api = LegalApi();
  final _scrollController = ScrollController();
  late Future<(List<LegalDocument>, LegalAcceptanceStatus?)> _data;
  bool _readToEnd = false;
  bool _submitting = false;
  String? _error;

  Future<(List<LegalDocument>, LegalAcceptanceStatus?)> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    final token = await AuthSessionStore.getToken();
    final documents = await _api.documents(lang);
    final status = token == null ? null : await _api.status(token);
    return (documents, status);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first load must run after localization is available.
    if (!_initialized) {
      _initialized = true;
      _data = _load();
    }
  }

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkReadToEnd);
  }

  void _checkReadToEnd() {
    if (_readToEnd || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter <= 24) {
      setState(() => _readToEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept(List<LegalDocument> documents) async {
    final token = await AuthSessionStore.getToken();
    if (token == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    LegalAcceptanceStatus? status;
    Object? failure;
    try {
      status = await _api.accept(token, documents);
    } catch (error) {
      failure = error;
      // The write may have succeeded even if the response timed out.
      try {
        status = await _api.status(token);
      } catch (_) {
        // Keep the original error for the user.
      }
    }
    try {
      if (!mounted) return;
      if (status?.current == true) {
        widget.onAccepted?.call();
        return;
      }
      if (failure is LegalApiException && failure.statusCode == 400) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        setState(() {
          _readToEnd = false;
          _data = _load();
        });
      }
      setState(() {
        _error = failure is LegalApiException
            ? failure.message
            : 'Nu am putut verifica acceptarea. Încearcă din nou.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.requireAcceptance,
        title: Text(isEnglish ? 'Legal documents' : 'Documente legale'),
      ),
      body: FutureBuilder<(List<LegalDocument>, LegalAcceptanceStatus?)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _data = _load()),
                child: Text(
                  isEnglish
                      ? 'Retry loading documents'
                      : 'Reîncearcă încărcarea documentelor',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (documents, status) = snapshot.data!;
          if (documents.isEmpty) {
            return const Center(
              child: Text('Documentele nu sunt disponibile.'),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _checkReadToEnd(),
          );
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.requireAcceptance
                                ? (isEnglish
                                      ? 'Read the documents below and scroll to the end to continue.'
                                      : 'Citește documentele de mai jos și derulează până la final pentru a continua.')
                                : (isEnglish
                                      ? 'Current PINLEND documents and your acceptance record'
                                      : 'Documentele PINLEND și dovada acceptării tale'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          for (final document in documents) ...[
                            Text(
                              document.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isEnglish ? 'Version' : 'Versiunea'} ${document.version}',
                            ),
                            if (status?.acceptedAt[document.id]
                                case final acceptedAt?)
                              Text(
                                '${isEnglish ? 'Accepted' : 'Acceptat'}: ${_formatDate(acceptedAt)}',
                                style: const TextStyle(
                                  color: Color(0xFF246A42),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 16),
                            SelectableText(
                              document.body,
                              style: const TextStyle(height: 1.5, fontSize: 15),
                            ),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.requireAcceptance)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (!_readToEnd)
                          Text(
                            isEnglish
                                ? 'Scroll to the end to enable acceptance.'
                                : 'Derulează până la final pentru a activa acceptarea.',
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _readToEnd && !_submitting
                                ? () => _accept(documents)
                                : null,
                            child: Text(
                              _submitting
                                  ? '...'
                                  : isEnglish
                                  ? 'I accept these documents'
                                  : 'Accept aceste documente',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
