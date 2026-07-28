import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController();

  static const _storageKey = 'app_language_code';
  static const romanian = Locale('ro');
  static const english = Locale('en');
  static const supportedLocales = [romanian, english];

  Locale _locale = romanian;
  bool _loaded = false;

  Locale get locale => _locale;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    _locale = _localeForCode(code);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final nextLocale = _localeForCode(locale.languageCode);

    if (_locale == nextLocale) {
      return;
    }

    _locale = nextLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, nextLocale.languageCode);
  }

  Future<void> toggle() {
    return setLocale(_locale.languageCode == 'ro' ? english : romanian);
  }

  static Locale _localeForCode(String? code) {
    return code == 'en' ? english : romanian;
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
