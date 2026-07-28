import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_language.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_api.dart';

void main() {
  runApp(const LendApp());
}

class LendApp extends StatefulWidget {
  const LendApp({super.key});

  @override
  State<LendApp> createState() => _LendAppState();
}

class _LendAppState extends State<LendApp> {
  final _languageController = AppLanguageController();

  @override
  void initState() {
    super.initState();
    _languageController.load();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: _languageController,
      child: AnimatedBuilder(
        animation: _languageController,
        builder: (context, _) {
          return MaterialApp(
            title: AppLocalizations(_languageController.locale).appName,
            debugShowCheckedModeBanner: false,
            locale: _languageController.locale,
            supportedLocales: AppLanguageController.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4A70A9),
                primary: const Color(0xFF4A70A9),
                surface: const Color(0xFFF9F9F9),
              ),
              fontFamily: 'Inter',
              useMaterial3: true,
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authApi = AuthApi();
  late final Future<bool> _isAuthenticated = _checkSession();

  Future<bool> _checkSession() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      return false;
    }

    try {
      await _authApi.me(token);
      return true;
    } catch (_) {
      await AuthSessionStore.clear();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticated,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _SplashScreen();
        }

        return snapshot.data! ? const MainShell() : const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEFECE3),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF30578F))),
    );
  }
}
