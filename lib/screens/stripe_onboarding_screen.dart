import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/lend_back_top_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripeOnboardingScreen extends StatefulWidget {
  const StripeOnboardingScreen({
    required this.url,
    this.forAccountDashboard = false,
    super.key,
  });

  final String url;
  final bool forAccountDashboard;

  @override
  State<StripeOnboardingScreen> createState() => _StripeOnboardingScreenState();
}

enum StripeOnboardingResult { completed, refreshRequested }

class _StripeOnboardingScreenState extends State<StripeOnboardingScreen> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (widget.forAccountDashboard) {
              return NavigationDecision.navigate;
            }
            final uri = Uri.tryParse(request.url);

            if (_isStripeReturnUrl(uri)) {
              Navigator.of(context).pop(StripeOnboardingResult.completed);
              return NavigationDecision.prevent;
            }

            if (_isStripeRefreshUrl(uri)) {
              Navigator.of(
                context,
              ).pop(StripeOnboardingResult.refreshRequested);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isStripeReturnUrl(Uri? uri) {
    return uri != null && uri.path == '/stripe/connect/return';
  }

  bool _isStripeRefreshUrl(Uri? uri) {
    return uri != null && uri.path == '/stripe/connect/refresh';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: LendBackTopBar.height,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: LendBackTopBar(
          title: widget.forAccountDashboard
              ? strings.choose('Contul de încasări', 'Payout account')
              : strings.choose('Configurează încasările', 'Set up payouts'),
          leadingIcon: Icons.close_rounded,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            IconButton(
              tooltip: strings.choose('Reîncarcă', 'Reload'),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
