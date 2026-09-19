import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Reusable soft neumorphic background widget matching the exact
/// radial gradient backdrop of the GitHub Pages site (docs/styles.css).
class NeuBackground extends StatelessWidget {
  final Widget child;
  final bool hasAmbientBlooms;

  const NeuBackground({
    super.key,
    required this.child,
    this.hasAmbientBlooms = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeuBackgroundPainter(hasAmbientBlooms: hasAmbientBlooms),
      child: child,
    );
  }
}

class _NeuBackgroundPainter extends CustomPainter {
  final bool hasAmbientBlooms;

  _NeuBackgroundPainter({this.hasAmbientBlooms = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Base solid neumorphic background (#E6ECF8)
    final bgPaint = Paint()..color = AppTheme.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final maxDim = math.max(size.width, size.height);

    // Top-Left soft white radial highlight (at 15% 15%)
    final topLeftCenter = Offset(size.width * 0.15, size.height * 0.15);
    final topLeftRadius = maxDim * 0.55;
    final topLeftPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: topLeftCenter, radius: topLeftRadius));
    canvas.drawCircle(topLeftCenter, topLeftRadius, topLeftPaint);

    // Bottom-Right darker neumorphic depth shadow (at 85% 85%)
    final botRightCenter = Offset(size.width * 0.85, size.height * 0.85);
    final botRightRadius = maxDim * 0.55;
    final botRightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC5D0E2).withOpacity(0.35),
          const Color(0xFFC5D0E2).withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: botRightCenter, radius: botRightRadius));
    canvas.drawCircle(botRightCenter, botRightRadius, botRightPaint);

    if (hasAmbientBlooms) {
      // Subtle royal blue ambient bloom at (12%, 18%)
      final blueCenter = Offset(size.width * 0.12, size.height * 0.18);
      final blueRadius = maxDim * 0.40;
      final bluePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2563EB).withOpacity(0.06),
            const Color(0xFF2563EB).withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: blueCenter, radius: blueRadius));
      canvas.drawCircle(blueCenter, blueRadius, bluePaint);

      // Subtle emerald green ambient bloom at (88%, 82%)
      final greenCenter = Offset(size.width * 0.88, size.height * 0.82);
      final greenRadius = maxDim * 0.42;
      final greenPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.05),
            const Color(0xFF10B981).withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: greenCenter, radius: greenRadius));
      canvas.drawCircle(greenCenter, greenRadius, greenPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuBackgroundPainter oldDelegate) {
    return oldDelegate.hasAmbientBlooms != hasAmbientBlooms;
  }
}
