import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/payments_api.dart';
import '../widgets/lend_back_top_bar.dart';
import '../widgets/lend_screen_frame.dart';
import 'stripe_onboarding_screen.dart';

class PayoutSettingsScreen extends StatefulWidget {
  const PayoutSettingsScreen({super.key});

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen>
    with WidgetsBindingObserver {
  static const _background = Color(0xFFF5F5F7);
  static const _blue = Color(0xFF4A70A9);
  static const _ink = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF626977);
  final _api = PaymentsApi();
  ConnectAccountStatus? _status;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<String> _token() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) {
      throw PaymentsApiException('Te rugăm să te autentifici.');
    }
    return token;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _api.getConnectStatus(await _token());
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).choose(
            'Nu putem actualiza încasările acum. Încearcă din nou peste puțin timp.',
            'We can’t update your payouts right now. Please try again shortly.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _chooseBusinessType() {
    final strings = AppLocalizations.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.choose('Cum vei încasa?', 'How will you get paid?'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.choose(
                  'Alege varianta potrivită pentru contul tău.',
                  'Choose the option that fits your account.',
                ),
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(strings.choose('Persoană fizică', 'Individual')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'individual'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.business_outlined),
                title: Text(strings.choose('Firmă', 'Business')),
                subtitle: _status?.isLive == false
                    ? Text(
                        strings.choose(
                          'Disponibil în curând',
                          'Available soon',
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _status?.isLive == false
                    ? null
                    : () => Navigator.pop(context, 'company'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOnboarding() async {
    if (_busy) return;
    final businessType = _status?.connected == true
        ? null
        : await _chooseBusinessType();
    if (_status?.connected != true && businessType == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final token = await _token();
      var nextType = businessType;
      while (mounted) {
        final url = await _api.createConnectOnboardingLink(
          token,
          businessType: nextType,
        );
        nextType = null;
        _validatedStripeUrl(url);
        if (!mounted) break;
        final result = await Navigator.of(context).push<StripeOnboardingResult>(
          MaterialPageRoute(builder: (_) => StripeOnboardingScreen(url: url)),
        );
        if (result != StripeOnboardingResult.refreshRequested) break;
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).choose(
            'Nu am putut deschide configurarea. Încearcă din nou.',
            'We couldn’t open setup. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Uri _validatedStripeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'stripe.com' || uri.host.endsWith('.stripe.com'))) {
      throw PaymentsApiException('Linkul Stripe nu este valid.');
    }
    return uri;
  }

  Future<void> _openDashboard() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = await _api.createConnectLoginLink(await _token());
      _validatedStripeUrl(url);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              StripeOnboardingScreen(url: url, forAccountDashboard: true),
        ),
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).choose(
            'Nu am putut deschide contul. Încearcă din nou.',
            'We couldn’t open your account. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = _status;
    final limited = status?.isLive == false;
    final ready = status?.isReady == true;
    final pending = status?.isPending == true;
    final needsAction = status?.needsAction == true;
    final title = status == null
        ? strings.choose('Încasările tale', 'Your payouts')
        : limited && status.connected
        ? strings.choose('Contul tău de încasări', 'Your payout account')
        : status.connected != true
        ? strings.choose(
            'Pregătește-ți încasările',
            'Get ready to receive payments',
          )
        : ready
        ? strings.choose('Poți primi bani', 'You can receive payments')
        : pending
        ? strings.choose(
            'Verificăm contul tău',
            'Your account is being reviewed',
          )
        : needsAction
        ? strings.choose('Mai este un pas', 'One more step')
        : strings.choose('Continuă configurarea', 'Finish setting up');
    final subtitle = status == null
        ? strings.choose(
            'Aici îți gestionezi contul pentru banii câștigați pe Lend.',
            'Manage the account for the money you earn on Lend.',
          )
        : limited && status.connected
        ? strings.choose(
            'Contul este conectat. Revenim cu detalii despre starea lui în curând.',
            'Your account is connected. More details will be available soon.',
          )
        : status.connected != true
        ? strings.choose(
            'Adaugă un cont pentru banii câștigați pe Lend.',
            'Set up an account for the money you earn on Lend.',
          )
        : ready
        ? strings.choose(
            'Contul tău pentru încasări este pregătit.',
            'Your payout account is ready.',
          )
        : pending
        ? strings.choose(
            'Revino aici pentru a vedea când este pregătit.',
            'Check back here to see when it is ready.',
          )
        : needsAction
        ? strings.choose(
            'Actualizează câteva informații pentru a putea primi bani.',
            'Update a few details to start receiving payments.',
          )
        : strings.choose(
            'Completează datele contului pentru a primi bani.',
            'Complete your account details to receive payments.',
          );

    return LendScreenFrame(
      backgroundColor: _background,
      child: Scaffold(
        backgroundColor: _background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(LendBackTopBar.height),
          child: LendBackTopBar(
            title: strings.choose('Încasări', 'Payouts'),
            actions: [
              IconButton(
                tooltip: strings.choose('Actualizează', 'Refresh'),
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              if (_loading && status == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Container(
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
                        child: Icon(
                          ready && !limited
                              ? Icons.check_circle_outline_rounded
                              : needsAction
                              ? Icons.priority_high_rounded
                              : Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 18),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.choose('CONTUL TĂU', 'YOUR ACCOUNT'),
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              ready && !limited
                                  ? Icons.verified_rounded
                                  : pending
                                  ? Icons.hourglass_top_rounded
                                  : Icons.account_balance_outlined,
                              color: ready && !limited
                                  ? const Color(0xFF218568)
                                  : _blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.connected
                                    ? strings.choose(
                                        'Contul de încasări este conectat',
                                        'Payout account connected',
                                      )
                                    : strings.choose(
                                        'Niciun cont conectat',
                                        'No account connected',
                                      ),
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (limited && status.connected) ...[
                          const SizedBox(height: 14),
                          Text(
                            strings.choose(
                              'Detaliile contului nu sunt disponibile momentan. Poți reveni aici oricând.',
                              'Account details are temporarily unavailable. You can check back anytime.',
                            ),
                            style: const TextStyle(color: _muted, height: 1.4),
                          ),
                        ],
                        if (status.connected && !ready && !limited) ...[
                          const SizedBox(height: 14),
                          Text(
                            needsAction
                                ? strings.choose(
                                    'Mai avem nevoie de câteva detalii de la tine.',
                                    'We need a few more details from you.',
                                  )
                                : pending
                                ? strings.choose(
                                    'Datele trimise sunt în curs de verificare.',
                                    'Your submitted details are being reviewed.',
                                  )
                                : strings.choose(
                                    'Configurarea contului nu este completă.',
                                    'Your account setup is not complete.',
                                  ),
                            style: const TextStyle(color: _muted, height: 1.4),
                          ),
                        ],
                        if (status.isLive ||
                            !status.connected ||
                            !status.payoutsEnabled ||
                            !status.detailsSubmitted) ...[
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _blue,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              onPressed: _busy
                                  ? null
                                  : ready || pending
                                  ? _openDashboard
                                  : _openOnboarding,
                              child: Text(
                                _busy
                                    ? strings.choose(
                                        'Se deschide...',
                                        'Opening...',
                                      )
                                    : ready || pending
                                    ? strings.choose(
                                        'Deschide contul',
                                        'Open account',
                                      )
                                    : status.connected
                                    ? strings.choose(
                                        'Completează detaliile',
                                        'Complete your details',
                                      )
                                    : strings.choose(
                                        'Configurează încasările',
                                        'Set up payouts',
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                _card(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: _blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.choose(
                                'Revenim imediat',
                                'Please try again',
                              ),
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              style: const TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                strings.choose('Reîncearcă', 'Try again'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 24,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}
