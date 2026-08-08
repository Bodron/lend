import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LendLogo extends StatelessWidget {
  const LendLogo({super.key, this.width = 140, this.height = 30});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pinlend',
      image: true,
      child: SvgPicture.asset(
        'assets/logo.svg',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
