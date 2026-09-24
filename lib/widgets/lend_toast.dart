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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: LendToastType.info,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show(
    BuildContext context, {
    required LendToastType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
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
          actionLabel: actionLabel,
          onAction: onAction,
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
    this.actionLabel,
    this.onAction,
  });

  final LendToastType type;
  final String message;
  final String? title;
  final Duration duration;
  final VoidCallback onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              actionLabel: widget.actionLabel,
              onAction: widget.onAction,
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
    this.actionLabel,
    this.onAction,
  });

  final LendToastType type;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);

    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(style.icon, color: style.accent, size: 36),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD1D1D1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: style.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ToastStyle _styleFor(LendToastType type) {
    return switch (type) {
      LendToastType.success => const _ToastStyle(
        accent: Color(0xFF79C96B),
        icon: Icons.check_circle_rounded,
      ),
      LendToastType.error => const _ToastStyle(
        accent: Color(0xFFFF5D6C),
        icon: Icons.error_rounded,
      ),
      LendToastType.warning => const _ToastStyle(
        accent: Color(0xFFFFCC53),
        icon: Icons.warning_rounded,
      ),
      LendToastType.info => const _ToastStyle(
        accent: Color(0xFF4E7BF4),
        icon: Icons.info_rounded,
      ),
    };
  }
}

class _ToastStyle {
  const _ToastStyle({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;
}
