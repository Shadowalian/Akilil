import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:core/core.dart';

/// Akilil brand mark — open spectrum arc + warm core (matches website SVG).
class BrandAssets {
  BrandAssets._();

  static Widget mark({double size = 56}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AkililMarkPainter(),
        size: Size(size, size),
      ),
    );
  }

  static Widget logo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark(size: 32),
        const SizedBox(width: 10),
        Text(
          'Akilil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: FriendColors.textPrimary,
            letterSpacing: -0.6,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _AkililMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * (5.4 / 40);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke / 2;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = FriendGradients.accentRing.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    // Open arc — same silhouette as website #i-mark
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.15,
      math.pi * 1.55,
      false,
      arcPaint,
    );

    final coreRadius = size.width * (5.4 / 40);
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [FriendColors.spark, FriendColors.coral],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));

    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
