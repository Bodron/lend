import 'package:flutter/material.dart';

/// Shared header for secondary screens with a back or close action.
class LendBackTopBar extends StatelessWidget {
  const LendBackTopBar({
    super.key,
    required this.title,
    this.titleContent,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFF1B1B1B),
    this.backButtonColor = const Color(0xFFF3F4F6),
    this.showDivider = true,
  });

  static const height = 76.0;

  final String title;
  final Widget? titleContent;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final IconData leadingIcon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color backButtonColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFE9EBEF)))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: backButtonColor,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: leadingIcon == Icons.close_rounded
                    ? MaterialLocalizations.of(context).closeButtonTooltip
                    : MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icon(leadingIcon, size: 21),
                color: foregroundColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                titleContent ??
                (subtitle == null
                    ? Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: 8), ...actions],
        ],
      ),
    );
  }
}
