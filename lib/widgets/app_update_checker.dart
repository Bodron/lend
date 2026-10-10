import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../services/push_notifications.dart';

class AppUpdateChecker extends StatefulWidget {
  const AppUpdateChecker({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker>
    with WidgetsBindingObserver {
  static const _previewEnabled = bool.fromEnvironment('APP_UPDATE_PREVIEW');
  final _service = AppUpdateService();
  bool _checking = false;
  bool _dialogOpen = false;
  String? _dismissedVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (!mounted || _checking || _dialogOpen) return;
    _checking = true;
    try {
      final offer = kDebugMode && _previewEnabled
          ? AppUpdateOffer(
              version: '1.0.1',
              url: Uri.parse(
                'https://play.google.com/store/apps/details?id=com.lend.ro',
              ),
              required: false,
              preview: true,
            )
          : await _service.check();
      if (!mounted ||
          offer == null ||
          (!offer.required && offer.version == _dismissedVersion)) {
        return;
      }
      final navigatorContext =
          PushNotifications.instance.navigatorKey.currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;

      _dialogOpen = true;
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: !offer.required,
        builder: (dialogContext) => PopScope(
          canPop: !offer.required,
          child: _UpdateDialog(offer: offer),
        ),
      );
      if (!offer.required) _dismissedVersion = offer.version;
    } finally {
      _dialogOpen = false;
      _checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.offer});

  final AppUpdateOffer offer;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _opening = false;
  bool _openFailed = false;

  Future<void> _openStore() async {
    if (_opening) return;
    if (widget.offer.preview) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _opening = true;
      _openFailed = false;
    });
    try {
      final opened = await launchUrl(
        widget.offer.url,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (opened && !widget.offer.required) {
        Navigator.of(context).pop();
      } else if (!opened) {
        setState(() => _openFailed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return AlertDialog(
      icon: Semantics(
        label: 'Pinlend',
        image: true,
        child: SvgPicture.asset('assets/logo_mark.svg', width: 72, height: 41),
      ),
      title: Text(english ? 'Update available' : 'Actualizare disponibilă'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.offer.required
                ? (english
                      ? 'Please update Pinlend to version ${widget.offer.version} to continue.'
                      : 'Actualizează Pinlend la versiunea ${widget.offer.version} pentru a continua.')
                : (english
                      ? 'Version ${widget.offer.version} is available. Update now for the latest improvements.'
                      : 'Versiunea ${widget.offer.version} este disponibilă. Actualizează acum pentru cele mai noi îmbunătățiri.'),
          ),
          if (_openFailed) ...[
            const SizedBox(height: 12),
            Text(
              english
                  ? 'The store could not be opened. Please try again.'
                  : 'Magazinul nu a putut fi deschis. Încearcă din nou.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.offer.required)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(english ? 'Later' : 'Mai târziu'),
          ),
        FilledButton(
          onPressed: _opening ? null : _openStore,
          child: Text(english ? 'Update' : 'Actualizează'),
        ),
      ],
    );
  }
}
