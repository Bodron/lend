import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/verification_api.dart';
import '../widgets/lend_back_top_bar.dart';
import '../widgets/lend_screen_frame.dart';

class TransactionVerificationScreen extends StatefulWidget {
  const TransactionVerificationScreen({
    super.key,
    this.forViewing = false,
    this.forProfile = false,
  });

  final bool forViewing;
  final bool forProfile;

  @override
  State<TransactionVerificationScreen> createState() =>
      _TransactionVerificationScreenState();
}

class _TransactionVerificationScreenState
    extends State<TransactionVerificationScreen>
    with WidgetsBindingObserver {
  static const _identityChannel = MethodChannel('lend/stripe_identity');
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF5E6673);
  static const _blue = Color(0xFF4A70A9);
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
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).choose(
            'Nu am putut afla starea verificării. Încearcă din nou.',
            'We could not check your verification status. Please try again.',
          ),
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
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).choose(
            'Nu am putut deschide verificarea. Încearcă din nou.',
            'We could not open verification. Please try again.',
          ),
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

    return LendScreenFrame(
      backgroundColor: _background,
      child: Scaffold(
        backgroundColor: _background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(LendBackTopBar.height),
          child: LendBackTopBar(
            title: strings.choose('Verificare', 'Verification'),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _intro(strings, status?.identityVerified == true),
              if (status?.identityVerified != true) const SizedBox(height: 20),
              if (status == null && _error == null)
                _card(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (status == null)
                _card(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: _muted,
                        size: 32,
                      ),
                      const SizedBox(height: 14),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: Text(strings.choose('Reîncearcă', 'Try again')),
                      ),
                    ],
                  ),
                )
              else if (!status.identityVerified)
                _statusCard(strings, status),
              if (status != null && _error != null) ...[
                const SizedBox(height: 16),
                _card(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: _blue),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!)),
                    ],
                  ),
                ),
              ],
              if (!widget.forProfile && !widget.forViewing) ...[
                const SizedBox(height: 20),
                _paymentNote(strings),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro(AppLocalizations strings, bool verified) {
    final subtitle = verified
        ? strings.choose(
            'Profilul tău este pregătit pentru închirieri și vizionări viitoare.',
            'Your profile is ready for future rentals and viewings.',
          )
        : widget.forProfile
        ? strings.choose(
            'Mai multă încredere la fiecare închiriere.',
            'More confidence with every rental.',
          )
        : widget.forViewing
        ? strings.choose(
            'Un pas simplu înainte de vizionare.',
            'One simple step before your viewing.',
          )
        : strings.choose(
            'Un pas simplu înainte de închiriere.',
            'One simple step before your rental.',
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF385F98), Color(0xFF7295C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            verified
                ? strings.choose('Identitate confirmată', 'Identity confirmed')
                : strings.choose(
                    'Confirmă-ți identitatea',
                    'Confirm your identity',
                  ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFEAF1FC),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (verified && !widget.forProfile) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(strings.choose('Continuă', 'Continue')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(AppLocalizations strings, VerificationStatus status) {
    final processing = status.processing;
    final title = processing
        ? strings.choose('Verificare în curs', 'Verification in progress')
        : strings.choose('Ești gata să începi?', 'Ready to get started?');
    final message = processing
        ? strings.choose(
            'Am primit informațiile tale. Rezultatul va apărea aici în curând.',
            'We have your information. Your result will appear here soon.',
          )
        : strings.choose(
            'Pregătește un act de identitate. Te ghidăm la fiecare pas.',
            'Have an ID document ready. We will guide you through each step.',
          );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  processing
                      ? Icons.hourglass_top_rounded
                      : Icons.badge_outlined,
                  color: _blue,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!processing) ...[
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE7EAF0)),
            const SizedBox(height: 20),
            _step(
              1,
              strings.choose(
                'Fotografiază actul de identitate',
                'Take a photo of your ID document',
              ),
            ),
            const SizedBox(height: 16),
            _step(2, strings.choose('Fă un selfie', 'Take a selfie')),
          ],
          if (!processing) ...[
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy ? null : _openIdentity,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        strings.choose(
                          'Începe verificarea',
                          'Start verification',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
          if (processing && widget.forProfile) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.choose('Închide', 'Close')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(int number, String label) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF1FC),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: _blue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentNote(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.choose(
                'Ai autorizat o plată? Suma rămâne rezervată până la confirmarea închirierii. Dacă cererea nu este acceptată în 48 de ore, rezervarea se anulează.',
                'Already authorized a payment? The amount stays on hold until the rental is confirmed. If the request is not accepted within 48 hours, the hold is released.',
              ),
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
