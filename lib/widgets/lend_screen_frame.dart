import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LendScreenFrame extends StatelessWidget {
  const LendScreenFrame({
    super.key,
    required this.backgroundColor,
    required this.child,
    this.bottomSafeArea = false,
  });

  final Color backgroundColor;
  final Widget child;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: bottomSafeArea,
          child: ColoredBox(color: backgroundColor, child: child),
        ),
      ),
    );
  }
}
