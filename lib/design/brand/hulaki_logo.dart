import 'package:flutter/widgets.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_typography.dart';

/// The Hulaki mark: a navigation arrow whose summit splits into the twin peak
/// of Machhapuchhre, over three dots for the trail. Drawn as vectors so it
/// stays crisp from a billboard down to a favicon.
class HulakiMark extends StatelessWidget {
  const HulakiMark({
    this.height = 28,
    this.color = AppColors.ink,
    super.key,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * _markAspect,
      child: CustomPaint(painter: _MarkPainter(color)),
    );
  }
}

/// The primary lockup: the mark beside the wordmark in Hanken Grotesk
/// ExtraBold.
class HulakiWordmark extends StatelessWidget {
  const HulakiWordmark({
    this.height = 24,
    this.color = AppColors.ink,
    this.fontSize = 22,
    super.key,
  });

  final double height;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HulakiMark(height: height, color: color),
        const SizedBox(width: 8),
        Text(
          'Hulaki',
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: color,
          ),
        ),
      ],
    );
  }
}

const double _markAspect = 100 / 84;

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 84.0;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    final peak = Path()
      ..moveTo(46 * sx, 13 * sy)
      ..lineTo(50 * sx, 23 * sy)
      ..lineTo(54 * sx, 13 * sy)
      ..lineTo(72 * sx, 58 * sy)
      ..lineTo(50 * sx, 46 * sy)
      ..lineTo(28 * sx, 58 * sy)
      ..close();
    canvas.drawPath(peak, paint);

    const dotR = 6.2;
    for (final cx in <double>[35, 50, 65]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx * sx, 74 * sy),
          width: dotR * 2 * sx,
          height: dotR * 2 * sy,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
