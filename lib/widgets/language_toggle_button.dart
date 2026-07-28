import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final controller = AppLanguageScope.of(context);
    final foreground = dark ? Colors.white : const Color(0xFF30578F);
    final background = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.86);

    return Tooltip(
      message: strings.switchToLanguage,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: controller.toggle,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              strings.languageCode,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
