import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/language_toggle_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _primary = Color(0xFF4A70A9);
  static const _backgroundImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCk2ufxl1A96CWQY6RebBOc6C50zXFuuQMJJDsyAMRmPoxMIpBMl0F3jkMZWi7-XWBjerQ4dpqBaQaXcWoRvEjo-qhDc58lNmMP3ysR5WHGn0ggqmZ8qG9VJMZSBzurQ-3wXltnTkI01cL--cbTDg6eTSfk47IAdrRpenSZ671Ouh9nZ1mwPX9IDpDd63I6BuG3XIwi2nCLxyY9F5TcQtQoArmZ54K7k3YkTLOiEcM47NI5HYzXHd8Kf4J-OVV3Gb9B_gi4zAukxjY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _backgroundImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: Color(0xFF303030));
            },
          ),
          const _BackgroundOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const _Header(),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 576),
                    child: const _HeroContent(),
                  ),
                  const SizedBox(height: 40),
                  const _FooterLinks(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openLogin(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
}

void _openRegister(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          strings.appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const LanguageToggleButton(),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => _openRegister(context),
              style: FilledButton.styleFrom(
                backgroundColor: HomeScreen._primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                strings.newAccount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final strings = AppLocalizations.of(context);
    final titleSize = width >= 768 ? 48.0 : 40.0;
    final subtitleSize = width >= 768 ? 20.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.heroTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.heroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: subtitleSize,
            height: 1.35,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryActionButton(
          label: strings.startNow,
          onPressed: () => _openRegister(context),
        ),
        const SizedBox(height: 16),
        _SecondaryActionButton(
          label: strings.alreadyHaveAccount,
          onPressed: () => _openLogin(context),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: HomeScreen._primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.60),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        Text(strings.terms, style: style),
        Text('•', style: style),
        Text(strings.privacy, style: style),
        Text('•', style: style),
        Text(strings.contact, style: style),
      ],
    );
  }
}

class _BackgroundOverlay extends StatelessWidget {
  const _BackgroundOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.60),
            Colors.black.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
      ),
    );
  }
}
