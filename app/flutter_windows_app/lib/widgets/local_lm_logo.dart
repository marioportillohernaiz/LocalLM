import 'package:flutter/widgets.dart';

class LocalLmLogo extends StatelessWidget {
  const LocalLmLogo({
    super.key,
    this.size = 32,
    this.backgroundColor,
    this.padding = 0,
    this.color,
  });

  final double size;
  final Color? backgroundColor;
  final double padding;

  // Kept for compatibility with existing call sites. The logo is rendered from
  // the provided bitmap asset and is not recolored.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final logo = Padding(
      padding: EdgeInsets.all(padding),
      child: ClipRect(
        child: Image.asset(
          'assets/images/logo.png',
          width: size - padding * 2,
          height: size - padding * 2,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          isAntiAlias: true,
        ),
      ),
    );

    if (backgroundColor == null) {
      return SizedBox.square(dimension: size, child: logo);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: logo,
    );
  }
}
