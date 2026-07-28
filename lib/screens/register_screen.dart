import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../widgets/language_toggle_button.dart';
import 'main_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFEFECE3);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.choose(
              'Trebuie sa accepti termenii pentru a continua.',
              'You must accept the terms to continue.',
            ),
          ),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.choose('Cont creat pentru', 'Account created for')} ${session.user.fullName}.',
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.choose(
              'Nu se poate conecta la server.',
              'Cannot connect to the server.',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
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
                AppLocalizations.of(context).choose(
                  '© 2024 BorrowIt. Economie colaborativa pentru un viitor mai bun.',
                  '© 2024 BorrowIt. Shared economy for a better future.',
                ),
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
          Text(
            strings.appName,
            style: const TextStyle(
              color: _RegisterScreenState._primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const LanguageToggleButton(),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _RegisterScreenState._primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              strings.choose('Ajutor', 'Help'),
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
                strings.choose('Creeaza cont', 'Create account'),
                style: const TextStyle(
                  color: _RegisterScreenState._primary,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.choose(
                  'Incepe sa imprumuti si sa oferi astazi.',
                  'Start borrowing and sharing today.',
                ),
                style: const TextStyle(
                  color: _RegisterScreenState._muted,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              _RegisterField(
                label: strings.choose('Nume complet', 'Full name'),
                icon: Icons.person_outline_rounded,
                hintText: strings.choose(
                  'Ex: Andrei Ionescu',
                  'Ex: Alex Smith',
                ),
                textInputAction: TextInputAction.next,
                controller: fullNameController,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.choose('Email', 'Email'),
                icon: Icons.mail_outline_rounded,
                hintText: strings.choose('nume@exemplu.ro', 'name@example.com'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.choose('Numar de telefon', 'Phone number'),
                icon: Icons.call_outlined,
                hintText: strings.choose('+40 7xx xxx xxx', '+1 555 000 0000'),
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _RegisterField(
                label: strings.choose('Parola', 'Password'),
                icon: Icons.lock_outline_rounded,
                hintText: strings.choose(
                  'Minim 8 caractere',
                  'At least 8 characters',
                ),
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
                          strings.choose('Creeaza cont', 'Create account'),
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
                    strings.choose('Ai deja cont?', 'Already have an account?'),
                    style: const TextStyle(
                      color: _RegisterScreenState._muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: _RegisterScreenState._primary,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.choose('Conecteaza-te', 'Sign in'),
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
        const _BorrowTrustBadge(),
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
                TextSpan(
                  text: strings.choose('Sunt de acord cu ', 'I agree to the '),
                ),
                TextSpan(
                  text: strings.choose(
                    'Termenii si conditiile',
                    'Terms and Conditions',
                  ),
                  style: const TextStyle(
                    color: _RegisterScreenState._primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: strings.choose(' si ', ' and ')),
                TextSpan(
                  text: strings.choose(
                    'Politica de confidentialitate',
                    'Privacy Policy',
                  ),
                  style: const TextStyle(
                    color: _RegisterScreenState._primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' BorrowIt.'),
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
                        strings.choose(
                          'Alatura-te comunitatii.',
                          'Join the community.',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.choose(
                          'Economisesti bani si protejezi mediul prin partajarea resurselor cu vecinii tai.',
                          'Save money and protect the environment by sharing resources with your neighbors.',
                        ),
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
                  color: _RegisterScreenState._primary,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.choose(
                        'Tranzactii securizate',
                        'Secure transactions',
                      ),
                      style: const TextStyle(
                        color: _RegisterScreenState._text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.choose(
                        'Fiecare membru este verificat pentru siguranta ta.',
                        'Every member is verified for your safety.',
                      ),
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

class _BorrowTrustBadge extends StatelessWidget {
  const _BorrowTrustBadge();

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
              color: Color(0xFF446085),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(
                context,
              ).choose('Securizat prin BorrowTrust', 'Secured by BorrowTrust'),
              style: const TextStyle(
                color: Color(0xFF446085),
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
