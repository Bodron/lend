import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripeOnboardingScreen extends StatefulWidget {
  const StripeOnboardingScreen({required this.url, super.key});

  final String url;

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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: LendBackTopBar.height,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: LendBackTopBar(
          title: 'Configurează plățile',
          leadingIcon: Icons.close_rounded,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            IconButton(
              tooltip: 'Reîncarcă',
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
