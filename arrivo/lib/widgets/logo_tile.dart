import 'package:flutter/material.dart';

/// The Arrivo logo: a simple location pin.
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Arrivo logo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/icon/arrivo_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
