import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import 'main_shell.dart';

class RentalContractScreen extends StatefulWidget {
  const RentalContractScreen({
    super.key,
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
  });

  final LendProduct product;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final int subtotal;
  final int serviceFee;
  final int total;

  @override
  State<RentalContractScreen> createState() => _RentalContractScreenState();
}

class _RentalContractScreenState extends State<RentalContractScreen> {
  static const _primary = Color(0xFF30578F);
  static const _secondary = Color(0xFF446085);
  static const _background = Color(0xFFF5F5F7);
  static const _surface = Color(0xFFF9F9F9);
  static const _surfaceContainer = Color(0xFFEEEEEE);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _error = Color(0xFFBA1A1A);

  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC1ghPKdxoO_3mmQ3RZgZxv5ytA_LRAUc9NlTMTVk9WPd3QoUt2lG9KZXGlrT50vj8PWFC9o3BVCWcryLMmlTgzPFE-zRoN2rPZCVWPpUuINt7-wsq5re-UanfPQURi1yF6sm8nLhOcVMwR1zscivEQqMISLMbPvXD1vokYsGmYDDsqKHGRGk1zGn2LV1m9lIcT9a7v_doOYN-zt5Tr4QsbivI1qlQ4bF68gd0hfDQxd-8bwl25fX8amy6e-LH0-21NffEO_U0-Rlc';

  final _rentalOrdersApi = RentalOrdersApi();
  final List<Offset?> _signaturePoints = [];
  bool _isSigning = false;
  bool _submitting = false;

  void _addPoint(Offset point) {
    setState(() {
      _signaturePoints.add(point);
    });
  }

  void _endStroke() {
    setState(() {
      _signaturePoints.add(null);
    });
  }

  void _clearSignature() {
    setState(_signaturePoints.clear);
  }

  void _setSigning(bool value) {
    if (_isSigning == value) {
      return;
    }

    setState(() {
      _isSigning = value;
    });
  }

  Future<void> _submitOrder() async {
    if (_signaturePoints.isEmpty || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final token = await AuthSessionStore.getToken();

      if (token == null) {
        throw RentalOrdersApiException('Trebuie sa fii autentificat.');
      }

      final order = await _rentalOrdersApi.create(
        accessToken: token,
        productId: widget.product.id,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comanda #${order.id} a fost trimisa.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const MainShell(initialIndex: 2),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
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
        child: Stack(
          children: [
            CustomScrollView(
              physics: _isSigning
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ContractTopBar()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 188),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _LegalDocumentCard(
                        product: widget.product,
                        rentalDays: widget.rentalDays,
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 680;
                          if (!wide) {
                            return Column(
                              children: [
                                _OwnerSignatureCard(
                                  ownerName: widget.product.ownerName,
                                ),
                                const SizedBox(height: 20),
                                _TenantSignatureCard(
                                  points: _signaturePoints,
                                  onPoint: _addPoint,
                                  onStrokeEnd: _endStroke,
                                  onClear: _clearSignature,
                                  onSigningChanged: _setSigning,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _OwnerSignatureCard(
                                  ownerName: widget.product.ownerName,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _TenantSignatureCard(
                                  points: _signaturePoints,
                                  onPoint: _addPoint,
                                  onStrokeEnd: _endStroke,
                                  onClear: _clearSignature,
                                  onSigningChanged: _setSigning,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _PricingBar(
                rentalDays: widget.rentalDays,
                total: widget.total,
                canSubmit: _signaturePoints.isNotEmpty && !_submitting,
                submitting: _submitting,
                onSubmit: _submitOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractTopBar extends StatelessWidget {
  const _ContractTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _RentalContractScreenState._surface.withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: _RentalContractScreenState._outline.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _RentalContractScreenState._text,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              ).choose('Contract si semnatura', 'Contract and signature'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _RentalContractScreenState._text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: Image.network(
                _RentalContractScreenState._avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: Color(0xFFE2E2E2));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({required this.product, required this.rentalDays});

  final LendProduct product;
  final int rentalDays;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _contractCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).choose('DOCUMENT LEGAL', 'LEGAL DOCUMENT'),
                    style: const TextStyle(
                      color: _RentalContractScreenState._muted,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FABD4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: _RentalContractScreenState._text,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).choose(
                            'Securizat de BorrowIt',
                            'Secured by BorrowIt',
                          ),
                          style: const TextStyle(
                            color: _RentalContractScreenState._text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 430),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LegalSection(
                      title: AppLocalizations.of(
                        context,
                      ).choose('1. Termeni generali', '1. General terms'),
                      body: AppLocalizations.of(context).choose(
                        'Acest acord de inchiriere stabileste conditiile sub care locatorul ofera bunul spre folosinta locatarului pentru perioada specificata.',
                        'This rental agreement sets the conditions under which the owner provides the item to the renter for the specified period.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _HighlightedLegalSection(
                      icon: Icons.gavel_rounded,
                      color: _RentalContractScreenState._text,
                      title: AppLocalizations.of(
                        context,
                      ).choose('Responsabilitate', 'Responsibility'),
                      body: AppLocalizations.of(context).choose(
                        'Locatarul isi asuma intreaga responsabilitate pentru integritatea bunului pe durata inchirierii. Orice dauna cauzata din neglijenta sau utilizare necorespunzatoare va fi suportata integral de catre locatar.',
                        'The renter assumes full responsibility for the item during the rental period. Any damage caused by negligence or improper use is covered by the renter.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HighlightedLegalSection(
                      icon: Icons.security_rounded,
                      color: _RentalContractScreenState._secondary,
                      title: AppLocalizations.of(
                        context,
                      ).choose('Garantie', 'Deposit'),
                      body: AppLocalizations.of(context).choose(
                        'Garantia retinuta prin platforma BorrowIt serveste ca asigurare pentru returnarea bunului in starea initiala. Aceasta va fi deblocata in termen de 24 de ore de la confirmarea returnarii.',
                        'The deposit held through BorrowIt secures the return of the item in its original condition. It is released within 24 hours after return confirmation.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LegalSection(
                      title: AppLocalizations.of(context).choose(
                        '3. Incetarea contractului',
                        '3. Contract termination',
                      ),
                      body: AppLocalizations.of(context).choose(
                        'Contractul pentru ${product.title} inceteaza automat la expirarea perioadei de $rentalDays zile sau prin acordul prealabil al ambelor parti in scris prin mesageria aplicatiei.',
                        'The contract for ${product.title} ends automatically when the $rentalDays day period expires or by prior written agreement between both parties through the app messaging system.',
                      ),
                    ),
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

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _RentalContractScreenState._text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: _RentalContractScreenState._muted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _HighlightedLegalSection extends StatelessWidget {
  const _HighlightedLegalSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _RentalContractScreenState._surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _RentalContractScreenState._text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: _RentalContractScreenState._muted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSignatureCard extends StatelessWidget {
  const _OwnerSignatureCard({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _contractCardDecoration,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.verified_rounded,
              color: _RentalContractScreenState._primary.withValues(
                alpha: 0.15,
              ),
              size: 64,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).choose('SEMNATURA PROPRIETAR', 'OWNER SIGNATURE'),
                  style: const TextStyle(
                    color: _RentalContractScreenState._muted,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 96,
                  child: Center(
                    child: Text(
                      ownerName.isEmpty ? 'Proprietar BorrowIt' : ownerName,
                      style: const TextStyle(
                        color: Color(0x6630578F),
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Divider(color: _RentalContractScreenState._outline),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _RentalContractScreenState._text,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).choose('Identitate verificata', 'Verified identity'),
                      style: const TextStyle(
                        color: _RentalContractScreenState._text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantSignatureCard extends StatelessWidget {
  const _TenantSignatureCard({
    required this.points,
    required this.onPoint,
    required this.onStrokeEnd,
    required this.onClear,
    required this.onSigningChanged,
  });

  final List<Offset?> points;
  final ValueChanged<Offset> onPoint;
  final VoidCallback onStrokeEnd;
  final VoidCallback onClear;
  final ValueChanged<bool> onSigningChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _contractCardDecoration.copyWith(
        border: Border.all(
          color: _RentalContractScreenState._primary.withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(
                context,
              ).choose('SEMNATURA LOCATAR (DVS.)', 'RENTER SIGNATURE (YOU)'),
              style: const TextStyle(
                color: _RentalContractScreenState._muted,
                fontSize: 12,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  onSigningChanged(true);
                  onPoint(event.localPosition);
                },
                onPointerMove: (event) => onPoint(event.localPosition),
                onPointerUp: (_) {
                  onStrokeEnd();
                  onSigningChanged(false);
                },
                onPointerCancel: (_) {
                  onStrokeEnd();
                  onSigningChanged(false);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: _SignaturePainter(points),
                    child: points.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.draw_rounded,
                                  color: Color(0xFF737781),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).choose('Semnati aici', 'Sign here'),
                                  style: const TextStyle(
                                    color: Color(0xFF737781),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: _RentalContractScreenState._error,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).choose('Sterge semnatura', 'Clear signature'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(
                    context,
                  ).choose('Utilizati degetul', 'Use your finger'),
                  style: const TextStyle(
                    color: _RentalContractScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final dotPaint = Paint()..color = const Color(0xFFD3E3FF);
    for (double x = 10; x < size.width; x += 20) {
      for (double y = 10; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    final borderPaint = Paint()
      ..color = _RentalContractScreenState._outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      borderPaint,
    );

    final strokePaint = Paint()
      ..color = _RentalContractScreenState._primary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _PricingBar extends StatelessWidget {
  const _PricingBar({
    required this.rentalDays,
    required this.total,
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
  });

  final int rentalDays;
  final int total;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding + 18),
      decoration: BoxDecoration(
        color: _RentalContractScreenState._surface.withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final totals = Row(
            children: [
              _TotalMetric(
                label: AppLocalizations.of(
                  context,
                ).choose('Durata totala', 'Total duration'),
                value: AppLocalizations.of(
                  context,
                ).choose('$rentalDays zile', '$rentalDays days'),
              ),
              const SizedBox(width: 18),
              const SizedBox(
                height: 40,
                child: VerticalDivider(
                  color: _RentalContractScreenState._outline,
                ),
              ),
              const SizedBox(width: 18),
              _TotalMetric(
                label: AppLocalizations.of(
                  context,
                ).choose('Pret total', 'Total price'),
                value: '$total RON',
              ),
            ],
          );

          final button = SizedBox(
            width: compact ? double.infinity : 230,
            height: 54,
            child: FilledButton.icon(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: _RentalContractScreenState._primary,
                disabledBackgroundColor: _RentalContractScreenState._outline
                    .withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              label: Text(
                submitting
                    ? AppLocalizations.of(
                        context,
                      ).choose('Se trimite...', 'Submitting...')
                    : AppLocalizations.of(
                        context,
                      ).choose('Semneaza si trimite', 'Sign and submit'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
            ),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [totals, const SizedBox(height: 16), button],
            );
          }

          return Row(
            children: [
              Expanded(child: totals),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _TotalMetric extends StatelessWidget {
  const _TotalMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _RentalContractScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _RentalContractScreenState._text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

final _contractCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: _RentalContractScreenState._outline.withValues(alpha: 0.30),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);
