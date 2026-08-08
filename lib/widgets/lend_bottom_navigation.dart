import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class LendBottomNavigation extends StatelessWidget {
  const LendBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onAddListing,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddListing;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = [
      LendBottomNavigationItem(Icons.search_rounded, strings.navExplore),
      LendBottomNavigationItem(Icons.list_alt_rounded, strings.navListings),
      LendBottomNavigationItem(Icons.handshake_outlined, strings.navRentals),
      LendBottomNavigationItem(
        Icons.person_outline_rounded,
        strings.navProfile,
      ),
    ];

    return SizedBox(
      height: 86,
      child: CustomPaint(
        painter: _LendBottomNavigationPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final selectedIndex = currentIndex.clamp(0, items.length - 1);
              final itemWidth = constraints.maxWidth / 5;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _LendNavigationButton(
                            item: items[0],
                            selected: selectedIndex == 0,
                            onPressed: () => onSelected(0),
                          ),
                        ),
                        Expanded(
                          child: _LendNavigationButton(
                            item: items[1],
                            selected: selectedIndex == 1,
                            onPressed: () => onSelected(1),
                          ),
                        ),
                        SizedBox(width: itemWidth),
                        Expanded(
                          child: _LendNavigationButton(
                            item: items[2],
                            selected: selectedIndex == 2,
                            onPressed: () => onSelected(2),
                          ),
                        ),
                        Expanded(
                          child: _LendNavigationButton(
                            item: items[3],
                            selected: selectedIndex == 3,
                            onPressed: () => onSelected(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Center(
                      child: _AddListingNavigationButton(
                        onPressed: onAddListing,
                        label: strings.choose('Adauga anunt', 'Add listing'),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 43,
                    child: SizedBox(
                      height: 14,
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInOutCubicEmphasized,
                        alignment: Alignment(
                          _indicatorAlignment(selectedIndex),
                          0,
                        ),
                        child: SizedBox(
                          width: itemWidth,
                          child: const Center(child: _SlidingIndicator()),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _indicatorAlignment(int selectedIndex) {
    return switch (selectedIndex) {
      0 => -1,
      1 => -0.5,
      2 => 0.5,
      _ => 1,
    };
  }
}

class _LendBottomNavigationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF050505);

    final path = Path()
      ..moveTo(0, 14)
      ..quadraticBezierTo(size.width / 2, 0, size.width, 14)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, background);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LendBottomNavigationItem {
  const LendBottomNavigationItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _LendNavigationButton extends StatelessWidget {
  const _LendNavigationButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final LendBottomNavigationItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Icon(item.icon, color: Colors.white, size: 27),
              ),
              const SizedBox(height: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                opacity: selected ? 1 : 0,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.70),
            blurRadius: 10,
          ),
        ],
      ),
      child: const SizedBox(width: 54, height: 3),
    );
  }
}

class _AddListingNavigationButton extends StatelessWidget {
  const _AddListingNavigationButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }
}

