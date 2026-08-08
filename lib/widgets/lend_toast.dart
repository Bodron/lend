import 'dart:async';

import 'package:flutter/material.dart';

enum LendToastType { success, error, warning, info }

class LendToast {
  const LendToast._();

  static OverlayEntry? _activeEntry;

  static void success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      type: LendToastType.success,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      type: LendToastType.error,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      type: LendToastType.warning,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void info(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      type: LendToastType.info,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required LendToastType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    _activeEntry?.remove();
    _activeEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _LendToastOverlay(
          type: type,
          title: title,
          message: message,
          duration: duration,
          onDismissed: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
            }
            entry.remove();
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _LendToastOverlay extends StatefulWidget {
  const _LendToastOverlay({
    required this.type,
    required this.message,
    required this.duration,
    required this.onDismissed,
    this.title,
  });

  final LendToastType type;
  final String message;
  final String? title;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_LendToastOverlay> createState() => _LendToastOverlayState();
}

class _LendToastOverlayState extends State<_LendToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isExiting || !mounted) {
      return;
    }

    setState(() {
      _isExiting = true;
    });

    await _controller.forward(from: 0);
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final offsetTween = _isExiting
        ? Tween<Offset>(begin: Offset.zero, end: const Offset(1.15, 0))
        : Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero);
    final opacityTween = _isExiting
        ? Tween<double>(begin: 1, end: 0)
        : Tween<double>(begin: 0, end: 1);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final curve = CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic,
            );

            return Opacity(
              opacity: opacityTween.evaluate(curve),
              child: SlideTransition(
                position: offsetTween.animate(curve),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: _LendToastContent(
              type: widget.type,
              title: widget.title,
              message: widget.message,
            ),
          ),
        ),
      ),
    );
  }
}

class _LendToastContent extends StatelessWidget {
  const _LendToastContent({
    required this.type,
    required this.message,
    this.title,
  });

  final LendToastType type;
  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);
    final resolvedTitle = title ?? _defaultTitle(context, type);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ToastStyle _styleFor(LendToastType type) {
    return switch (type) {
      LendToastType.success => const _ToastStyle(
        accent: Color(0xFF2E7D5B),
        borderColor: Color(0xFFD7EADF),
        icon: Icons.check_rounded,
      ),
      LendToastType.error => const _ToastStyle(
        accent: Color(0xFFC2413B),
        borderColor: Color(0xFFF1D3D1),
        icon: Icons.close_rounded,
      ),
      LendToastType.warning => const _ToastStyle(
        accent: Color(0xFFB26A00),
        borderColor: Color(0xFFF2DFBF),
        icon: Icons.priority_high_rounded,
      ),
      LendToastType.info => const _ToastStyle(
        accent: Color(0xFF4A70A9),
        borderColor: Color(0xFFD5DEEC),
        icon: Icons.info_outline_rounded,
      ),
    };
  }

  String _defaultTitle(BuildContext context, LendToastType type) {
    final isRomanian = Localizations.localeOf(context).languageCode == 'ro';

    return switch (type) {
      LendToastType.success => isRomanian ? 'Succes' : 'Success',
      LendToastType.error => isRomanian ? 'Eroare' : 'Error',
      LendToastType.warning => isRomanian ? 'Atentie' : 'Warning',
      LendToastType.info => isRomanian ? 'Info' : 'Info',
    };
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.accent,
    required this.borderColor,
    required this.icon,
  });

  final Color accent;
  final Color borderColor;
  final IconData icon;
}
