import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/generated_localizations.dart';
import '../services/auth_api.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/lend_logo.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';
import 'main_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _surfaceLow = Color(0xFFF3F3F3);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFF737781);
  static const _imageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuABBRng4qJlsCUq6g8txEyU_pd4-EkkWVSIaeOGApvIwnmz9OJ62pBuKM9sh8JQsmnty9ZBo5HFVyhfD_hR-3hWFO5eaU_spQgwfPicbVuM_ug3svBQiwKvWLIunT3BbATCTiq0zsU8QIJt2kC-bxvXhr8ndAxcNvrjtHrZLMaCtlblMZhpDMPgqIxZthvd7ehjkcTGFqDnx0bWXKWzTeSTG5i4rcDwECJUdHpZvr34ZZvTazj17wuhwBP2PgDNG1ATn3vgePJOiVw';

  final _authApi = AuthApi();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _showPassword = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final strings = AppLocalizations.of(context);

    if (!_acceptedTerms) {
      LendToast.warning(context, message: strings.acceptTermsWarning);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await _authApi.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      LendToast.success(
        context,
        message: '${strings.accountCreatedFor} ${session.user.fullName}.',
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
      LendToast.error(context, message: strings.cannotConnectServer);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LendScreenFrame(
      backgroundColor: _background,
      child: Column(
        children: [
          const _RegisterHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final form = _RegisterColumn(
                        acceptedTerms: _acceptedTerms,
                        showPassword: _showPassword,
                        isSubmitting: _isSubmitting,
                        fullNameController: _fullNameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                        passwordController: _passwordController,
                        onTermsChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                        onTogglePassword: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        onOpenLogin: _openLogin,
                        onSubmit: _register,
                      );

                      if (!isWide) {
                        return form;
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: _VisualPanel()),
                          const SizedBox(width: 80),
                          SizedBox(width: 448, child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              GeneratedLocalizations.of(context).registerFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x99737781),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E2E2).withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        children: [
          const LendLogo(),
          const Spacer(),
          const LanguageToggleButton(),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _RegisterScreenState._text,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              strings.help,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterColumn extends StatelessWidget {
  const _RegisterColumn({
    required this.acceptedTerms,
    required this.showPassword,
    required this.isSubmitting,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.onTermsChanged,
    required this.onTogglePassword,
    required this.onOpenLogin,
    required this.onSubmit,
  });

  final bool acceptedTerms;
  final bool showPassword;
  final bool isSubmitting;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onOpenLogin;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E2E2).withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.createAccount,
                style: const TextStyle(
                  color: _RegisterScreenState._text,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.createAccountSubtitle,
                style: const TextStyle(
                  color: _RegisterScreenState._muted,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              _RegisterField(
                label: strings.fullName,
                icon: Icons.person_outline_rounded,
                hintText: strings.fullNameHint,
                textInputAction: TextInputAction.next,
                controller: fullNameController,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.email,
                icon: Icons.mail_outline_rounded,
                hintText: strings.emailHint,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.phoneNumber,
                icon: Icons.call_outlined,
                hintText: strings.phoneHint,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.password,
                icon: Icons.lock_outline_rounded,
                hintText: strings.passwordMinHint,
                controller: passwordController,
                obscureText: !showPassword,
                onFieldSubmitted: (_) => onSubmit(),
                trailing: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _RegisterScreenState._outline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _TermsCheckbox(value: acceptedTerms, onChanged: onTermsChanged),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _RegisterScreenState._primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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
                          strings.createAccount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    strings.alreadyHaveAccountQuestion,
                    style: const TextStyle(
                      color: _RegisterScreenState._muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: _RegisterScreenState._text,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.signIn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const _LendTrustBadge(),
      ],
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.label,
    required this.icon,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: _RegisterScreenState._muted,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          obscureText: obscureText,
          style: const TextStyle(
            color: _RegisterScreenState._text,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _RegisterScreenState._surfaceLow,
            hintText: hintText,
            hintStyle: TextStyle(
              color: _RegisterScreenState._outline.withValues(alpha: 0.65),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: _RegisterScreenState._outline),
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(
              _RegisterScreenState._primary.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _RegisterScreenState._primary,
            side: const BorderSide(color: Color(0xFFC3C6D1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: _RegisterScreenState._muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: strings.iAgreeTo),
                TextSpan(
                  text: strings.termsAndConditions,
                  style: const TextStyle(
                    color: _RegisterScreenState._text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: strings.andWord),
                TextSpan(
                  text: strings.privacyPolicy,
                  style: const TextStyle(
                    color: _RegisterScreenState._text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' Lend.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualPanel extends StatelessWidget {
  const _VisualPanel();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _RegisterScreenState._imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(color: Color(0xFFE5E2D9));
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _RegisterScreenState._primary.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.joinCommunity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.joinCommunityBody,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFD3E3FF),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: _RegisterScreenState._text,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.secureTransactions,
                      style: const TextStyle(
                        color: _RegisterScreenState._text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.secureTransactionsBody,
                      style: const TextStyle(
                        color: _RegisterScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LendTrustBadge extends StatelessWidget {
  const _LendTrustBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF446085).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: _RegisterScreenState._text,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              GeneratedLocalizations.of(context).securedByLendTrust,
              style: const TextStyle(
                color: _RegisterScreenState._text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
