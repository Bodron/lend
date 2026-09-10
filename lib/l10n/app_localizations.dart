import 'generated_localizations.dart';

typedef AppLocalizations = GeneratedLocalizations;

extension AppLocalizationsCompatibility on GeneratedLocalizations {
  bool get isRomanian => localeName.startsWith('ro');

  String get languageCode => isRomanian ? 'RO' : 'EN';
  String get switchToLanguage => isRomanian ? 'English' : 'Rom\u00e2n\u0103';

  // Temporary bridge while the remaining screens are migrated to named
  // gen_l10n keys. The old correction maps were removed; ARB files are now
  // the source of truth for all migrated strings.
  String choose(String ro, String en) => isRomanian ? ro : en;
}
