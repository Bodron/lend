import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../widgets/lend_bottom_navigation.dart';
import 'add_listing_screen.dart';
import 'main_shell.dart';

class ReturnQrScreen extends StatelessWidget {
  const ReturnQrScreen({
    super.key,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.returnCode,
  });

  final String itemTitle;
  final String itemImageUrl;
  final String returnCode;

  static const _primary = Color(0xFF30578F);
  static const _secondary = Color(0xFF446085);
  static const _secondaryContainer = Color(0xFFB7D3FE);
  static const _background = Color(0xFFF5F5F7);
  static const _surface = Color(0xFFF9F9F9);
  static const _surfaceLow = Color(0xFFF3F3F3);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outlineVariant = Color(0xFFC3C6D1);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _ReturnTopBar(title: itemTitle)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 138),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _ReturnStatusBadge(),
                      const SizedBox(height: 8),
                      _ReturnQrCard(
                        itemTitle: itemTitle,
                        itemImageUrl: itemImageUrl,
                        returnCode: returnCode,
                      ),
                      const SizedBox(height: 20),
                      _SecondaryActionButton(
                        icon: Icons.report_problem_outlined,
                        label: strings.choose(
                          'Raporteaza o problema',
                          'Report a problem',
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      _PrimaryActionButton(
                        icon: Icons.support_agent_rounded,
                        label: strings.choose(
                          'Contact support',
                          'Contact support',
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 34),
                      const _SecurityNote(),
                    ]),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: LendBottomNavigation(
                currentIndex: 2,
                onAddListing: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddListingScreen(),
                    ),
                  );
                },
                onSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShell(),
                      ),
                      (route) => false,
                    );
                  }
                  if (index == 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShell(initialIndex: 1),
                      ),
                    );
                  }
                  if (index == 2) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShell(initialIndex: 2),
                      ),
                    );
                  }
                  if (index == 3) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShell(initialIndex: 3),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnTopBar extends StatelessWidget {
  const _ReturnTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReturnQrScreen._surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: ReturnQrScreen._outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
            color: ReturnQrScreen._text,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              ).choose('Finalizare retur', 'Complete return'),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReturnQrScreen._text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ReturnStatusBadge extends StatelessWidget {
  const _ReturnStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ReturnQrScreen._secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ReturnQrScreen._secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(
                  context,
                ).choose('Retur in curs', 'Return in progress'),
                style: const TextStyle(
                  color: ReturnQrScreen._text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnQrCard extends StatelessWidget {
  const _ReturnQrCard({
    required this.itemTitle,
    required this.itemImageUrl,
    required this.returnCode,
  });

  final String itemTitle;
  final String itemImageUrl;
  final String returnCode;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Text(
              strings.choose(
                'Arata acest cod proprietarului',
                'Show this code to the owner',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ReturnQrScreen._text,
                fontSize: 24,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.choose(
                'Proprietarul trebuie sa scaneze codul pentru a confirma primirea produsului in bune conditii.',
                'The owner needs to scan this code to confirm the item was received in good condition.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ReturnQrScreen._muted,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            _QrShell(returnCode: returnCode),
            const SizedBox(height: 28),
            _ReturnItemSummary(title: itemTitle, imageUrl: itemImageUrl),
          ],
        ),
      ),
    );
  }
}

class _QrShell extends StatelessWidget {
  const _QrShell({required this.returnCode});

  final String returnCode;

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.sizeOf(context).width.clamp(0, 380) * 0.58;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: qrSize + 42,
          height: qrSize + 42,
          decoration: BoxDecoration(
            color: ReturnQrScreen._primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: ReturnQrScreen._outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: qrSize.toDouble(),
            child: QrImageView(
              data: returnCode,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ReturnQrScreen._primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ReturnQrScreen._primary,
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnItemSummary extends StatelessWidget {
  const _ReturnItemSummary({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReturnQrScreen._surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ReturnQrScreen._outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(color: Color(0xFFE2E2E2));
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).choose('Obiectul returnat', 'Returned item'),
                    style: const TextStyle(
                      color: ReturnQrScreen._muted,
                      fontSize: 11,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReturnQrScreen._text,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ReturnQrScreen._secondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: ReturnQrScreen._secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: ReturnQrScreen._muted,
          backgroundColor: Colors.white,
          side: const BorderSide(color: ReturnQrScreen._outlineVariant),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: ReturnQrScreen._primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, color: ReturnQrScreen._secondary),
            const SizedBox(width: 8),
            Text(
              strings.choose('Tranzactie securizata', 'Secure transaction'),
              style: const TextStyle(
                color: ReturnQrScreen._secondary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          strings.choose(
            'Garantia ta va fi deblocata automat imediat ce proprietarul confirma starea obiectului.',
            'Your deposit will be released automatically after the owner confirms the item condition.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReturnQrScreen._muted,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

