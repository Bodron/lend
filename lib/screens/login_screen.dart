import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/lend_logo.dart';
import '../widgets/lend_toast.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const _primary = Color(0xFF4A70A9);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF202124);
  static const _muted = Color(0xFF5F6673);
  static const _outline = Color(0xFFC3C9D6);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final _authApi = AuthApi();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn.instance;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _isAppleSubmitting = false;
  bool _isGoogleInitialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final strings = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      LendToast.success(
        context,
        message:
            '${strings.choose('Bine ai revenit', 'Welcome back')}, ${session.user.fullName}!',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      LendToast.error(context, message: error.message);
    } catch (_) {
      if (!mounted) return;
      LendToast.error(
        context,
        message: strings.choose(
          'Nu se poate conecta la server.',
          'Cannot connect to the server.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _loginWithApple() async {
    final strings = AppLocalizations.of(context);

    setState(() {
      _isAppleSubmitting = true;
    });

    try {
      final nonce = _randomNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw AuthApiException(
          strings.choose(
            'Apple nu a returnat un token de autentificare.',
            'Apple did not return an authentication token.',
          ),
        );
      }

      final session = await _authApi.loginWithApple(
        identityToken: identityToken,
        fullName: _appleFullName(
          credential.givenName,
          credential.familyName,
        ),
        nonce: nonce,
      );

      if (!mounted) return;

      LendToast.success(
        context,
        message:
            '${strings.choose('Bine ai revenit', 'Welcome back')}, ${session.user.fullName}!',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted) return;
      if (error.code == AuthorizationErrorCode.canceled) {
        return;
      }

      LendToast.error(
        context,
        message: strings.choose(
          'Autentificarea cu Apple nu a reusit.',
          'Apple sign-in failed.',
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      LendToast.error(context, message: error.message);
    } catch (_) {
      if (!mounted) return;
      LendToast.error(
        context,
        message: strings.choose(
          'Nu se poate conecta la server.',
          'Cannot connect to the server.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAppleSubmitting = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final strings = AppLocalizations.of(context);

    setState(() {
      _isGoogleSubmitting = true;
    });

    try {
      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize(
          clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
          serverClientId: _googleServerClientId.isEmpty
              ? null
              : _googleServerClientId,
        );
        _isGoogleInitialized = true;
      }

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthApiException(
          strings.choose(
            'Google nu a returnat un token de autentificare.',
            'Google did not return an authentication token.',
          ),
        );
      }

      final session = await _authApi.loginWithGoogle(
        idToken: idToken,
        fullName: account.displayName,
      );

      if (!mounted) return;

      LendToast.success(
        context,
        message:
            '${strings.choose('Bine ai revenit', 'Welcome back')}, ${session.user.fullName}!',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      LendToast.error(
        context,
        message: strings.choose(
          'Autentificarea cu Google nu a reusit.',
          'Google sign-in failed.',
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      LendToast.error(context, message: error.message);
    } catch (_) {
      if (!mounted) return;
      LendToast.error(
        context,
        message: strings.choose(
          'Nu se poate conecta la server.',
          'Cannot connect to the server.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  String? _appleFullName(String? givenName, String? familyName) {
    final parts = [givenName, familyName]
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();

    return parts.isEmpty ? null : parts.join(' ');
  }

  String _randomNonce() {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();

    return List.generate(
      32,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 850;

    return Scaffold(
      backgroundColor: LoginScreen._background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _LoginHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: isCompact ? 16 : 28),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: _LoginCard(
                          isCompact: isCompact,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isSubmitting: _isSubmitting,
                          isGoogleSubmitting: _isGoogleSubmitting,
                          isAppleSubmitting: _isAppleSubmitting,
                          onSubmit: _login,
                          onGoogleSubmit: _loginWithGoogle,
                          onAppleSubmit: _loginWithApple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _TrustBadge(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF1F2933),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          const SizedBox(width: 8),
          const LendLogo(),
          const Spacer(),
          const LanguageToggleButton(),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.isCompact,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.isGoogleSubmitting,
    required this.isAppleSubmitting,
    required this.onSubmit,
    required this.onGoogleSubmit,
    required this.onAppleSubmit,
  });

  final bool isCompact;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final bool isGoogleSubmitting;
  final bool isAppleSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSubmit;
  final VoidCallback onAppleSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(24, isCompact ? 24 : 26, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.choose('Bine ai revenit', 'Welcome back'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LoginScreen._text,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.choose(
              'Intra in contul tau pentru a continua',
              'Sign in to your account to continue',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LoginScreen._muted,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isCompact ? 32 : 46),
          _FieldLabel(strings.choose('Email', 'Email')),
          const SizedBox(height: 6),
          _LoginInput(
            icon: Icons.mail_outline_rounded,
            controller: emailController,
            hintText: strings.choose('nume@exemplu.ro', 'name@example.com'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: isCompact ? 18 : 24),
          _FieldLabel(strings.choose('Parola', 'Password')),
          const SizedBox(height: 6),
          _LoginInput(
            icon: Icons.lock_outline_rounded,
            controller: passwordController,
            hintText: strings.choose('Parola ta', 'Your password'),
            trailing: Icons.visibility_outlined,
            obscureText: true,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: LoginScreen._text,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                strings.choose('Am uitat parola', 'Forgot password'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 22 : 26),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: LoginScreen._primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      strings.choose('Conecteaza-te', 'Sign in'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          SizedBox(height: isCompact ? 34 : 48),
          const _DividerLabel(),
          SizedBox(height: isCompact ? 26 : 36),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  assetPath: 'assets/auth/google_g.png',
                  label: 'Google',
                  isLoading: isGoogleSubmitting,
                  onPressed: isSubmitting ||
                          isGoogleSubmitting ||
                          isAppleSubmitting
                      ? null
                      : onGoogleSubmit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  assetPath: 'assets/auth/apple_logo.png',
                  label: 'Apple',
                  isLoading: isAppleSubmitting,
                  onPressed: isSubmitting ||
                          isGoogleSubmitting ||
                          isAppleSubmitting
                      ? null
                      : onAppleSubmit,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 32 : 52),
          const _CreateAccountPrompt(),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4D5562),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.icon,
    required this.controller,
    required this.hintText,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final IconData? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          color: LoginScreen._text,
          fontSize: obscureText ? 18 : 16,
          fontWeight: FontWeight.w500,
          letterSpacing: obscureText ? 2.4 : 0,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF77808D),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 22, color: const Color(0xFF77808D)),
          suffixIcon: trailing == null
              ? null
              : Icon(trailing, size: 23, color: const Color(0xFF77808D)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          border: _inputBorder(LoginScreen._outline),
          enabledBorder: _inputBorder(LoginScreen._outline),
          focusedBorder: _inputBorder(LoginScreen._primary),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: LoginScreen._outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(
              context,
            ).choose('SAU CONTINUA CU', 'OR CONTINUE WITH'),
            style: const TextStyle(
              color: Color(0xFF7A828E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Expanded(child: Divider(color: LoginScreen._outline)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.assetPath,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String assetPath;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.asset(
                assetPath,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: LoginScreen._text,
          backgroundColor: Colors.white,
          side: const BorderSide(color: LoginScreen._outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          strings.choose('Nu ai un cont?', 'Do not have an account?'),
          style: const TextStyle(
            color: LoginScreen._muted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: LoginScreen._text,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            strings.choose('Creeaza cont nou', 'Create new account'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EBEF).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_rounded,
              size: 18,
              color: LoginScreen._text,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                AppLocalizations.of(context).choose(
                  'Comunitate sigura si verificata',
                  'Safe and verified community',
                ),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoginScreen._text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
