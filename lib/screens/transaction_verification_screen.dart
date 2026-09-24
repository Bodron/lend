import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/verification_api.dart';

class TransactionVerificationScreen extends StatefulWidget {
  const TransactionVerificationScreen({super.key});

  @override
  State<TransactionVerificationScreen> createState() =>
      _TransactionVerificationScreenState();
}

class _TransactionVerificationScreenState
    extends State<TransactionVerificationScreen>
    with WidgetsBindingObserver {
  static const _identityChannel = MethodChannel('lend/stripe_identity');
  final _api = VerificationApi();
  VerificationStatus? _status;
  Timer? _poll;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<String> _token() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) throw Exception('Trebuie sa fii autentificat.');
    return token;
  }

  Future<void> _refresh() async {
    if (_busy) return;
    try {
      final status = await _api.status(await _token());
      if (!mounted) return;
      setState(() {
        _status = status;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _run(Future<void> Function(String token) action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(await _token());
      if (mounted) await _refreshAfterAction();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAfterAction() async {
    final status = await _api.status(await _token());
    if (mounted) setState(() => _status = status);
  }

  Future<void> _openIdentity() => _run((token) async {
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (mobile) {
      final session = await _api.startNativeIdentity(token);
      if (session == null) return;
      final result = await _identityChannel.invokeMethod<String>(
        'presentIdentity',
        {
          'sessionId': session.id,
          'ephemeralKeySecret': session.ephemeralKeySecret,
        },
      );
      if (result == 'failed') {
        throw Exception(
          'Verificarea Stripe Identity nu a putut fi finalizata.',
        );
      }
      return;
    }
    final url = await _api.startIdentity(token);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'stripe.com' || uri.host.endsWith('.stripe.com'))) {
      throw Exception('Linkul Stripe Identity nu este valid.');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Nu am putut deschide Stripe Identity.');
    }
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.choose('Verificarea identitatii', 'Identity verification'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              strings.choose(
                'Verifica-ti identitatea pentru aceasta inchiriere. Verificarea ramane valabila pentru urmatoarele inchirieri.',
                'Verify your identity for this rental. The result is reused for future rentals.',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.choose(
                'Daca ai autorizat deja plata, suma este doar rezervata pe card. Daca inchirierea nu este acceptata in 48 de ore, rezervarea sumei se anuleaza.',
                'If you have authorized payment, the amount is only held on your card. If the rental is not accepted within 48 hours, the hold is canceled.',
              ),
            ),
            const SizedBox(height: 20),
            if (status == null)
              const Center(child: CircularProgressIndicator()),
            if (status != null) ...[
              ListTile(
                leading: Icon(
                  status.identityVerified
                      ? Icons.check_circle
                      : Icons.badge_outlined,
                ),
                title: Text(
                  strings.choose('Buletin si selfie', 'ID document and selfie'),
                ),
                trailing: status.identityVerified
                    ? null
                    : TextButton(
                        onPressed: _busy ? null : _openIdentity,
                        child: Text(strings.choose('Verifica', 'Verify')),
                      ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: status.complete
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(strings.choose('Continua', 'Continue')),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
