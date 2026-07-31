import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'language_toggle_button.dart';

class LendTopBar extends StatelessWidget {
  const LendTopBar({
    super.key,
    required this.title,
    required this.avatarUrl,
    this.onNotificationPressed,
    this.hasUnreadNotifications = false,
  });

  final String title;
  final String avatarUrl;
  final VoidCallback? onNotificationPressed;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return SizedBox(
      height: 82,
      child: CustomPaint(
        painter: _LendTopBarPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Color(0xFF202020),
                        child: Icon(Icons.person, color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _localizedTitle(strings, title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotificationPressed ?? () {},
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (hasUnreadNotifications)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF050505),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const LanguageToggleButton(dark: true),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedTitle(AppLocalizations strings, String value) {
    final normalized = value.toLowerCase();

    if (value == strings.appName || normalized == 'borrowit') {
      return strings.appName;
    }

    if (normalized.contains('anun') || normalized.contains('listings')) {
      return strings.choose('Anunturile mele', 'My listings');
    }

    if (normalized.contains('inchir') || normalized.contains('rental')) {
      return strings.choose('Inchirierile mele', 'My rentals');
    }

    if (normalized.contains('profil') || normalized.contains('profile')) {
      return strings.choose('Profilul meu', 'My profile');
    }

    return value;
  }
}

class _LendTopBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF050505);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 60)
      ..quadraticBezierTo(size.width / 2, 82, 0, 60)
      ..close();

    canvas.drawPath(path, background);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
