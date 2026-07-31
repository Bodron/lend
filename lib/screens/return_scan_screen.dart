import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/rental_orders_api.dart';

class ReturnScanScreen extends StatefulWidget {
  const ReturnScanScreen({super.key});

  @override
  State<ReturnScanScreen> createState() => _ReturnScanScreenState();
}

class _ReturnScanScreenState extends State<ReturnScanScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);

  final _rentalOrdersApi = RentalOrdersApi();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isCompleting = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isCompleting) {
      return;
    }

    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;

    final orderId = _orderIdFromCode(code);

    if (orderId == null) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      await _scannerController.stop();
      final token = await AuthSessionStore.getToken();

      if (token == null) {
        throw RentalOrdersApiException('Trebuie sa fii autentificat.');
      }

      await _rentalOrdersApi.completeReturn(
        accessToken: token,
        orderId: orderId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isCompleting = false;
      });
      await _scannerController.start();
    }
  }

  String? _orderIdFromCode(String? code) {
    const prefix = 'borrowit:return:';

    if (code == null || !code.startsWith(prefix)) {
      return null;
    }

    final orderId = code.substring(prefix.length).trim();
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(orderId) ? orderId : null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _handleDetection,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ScannerTopBar(
                title: strings.choose('Scaneaza returul', 'Scan return'),
              ),
            ),
            Center(
              child: Container(
                width: 236,
                height: 236,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCompleting
                            ? Icons.hourglass_top_rounded
                            : Icons.qr_code_scanner_rounded,
                        color: _primary,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCompleting
                            ? strings.choose(
                                'Confirm returul...',
                                'Confirming return...',
                              )
                            : strings.choose(
                                'Scaneaza codul QR afisat de chirias.',
                                'Scan the QR code shown by the renter.',
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.choose(
                          'Dupa scanare, inchirierea este marcata ca finalizata.',
                          'After scanning, the rental is marked completed.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(false),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
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
