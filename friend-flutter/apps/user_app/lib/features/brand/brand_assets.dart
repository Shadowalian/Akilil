import 'package:friend_user/l10n/tr.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:core/core.dart';

/// Akilil brand mark — open spectrum arc + warm core (matches website SVG).
class BrandAssets {
  BrandAssets._();

  /// The Akilil mark: an open teal ring around a clay core.
  static Widget mark({double size = 56, Color color = FriendColors.primary, Color core = FriendColors.accent}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AkililMarkPainter(color: color, coreColor: core),
        size: Size(size, size),
      ),
    );
  }

  /// Mark plus wordmark, for the top of auth screens.
  static Widget logo({double size = 26}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark(size: size),
        const SizedBox(width: 8),
        Text(
          tr('Akilil'),
          style: friendFont(
            fontWeight: FontWeight.w600,
            fontSize: size * 0.72,
            color: FriendColors.textPrimary,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _AkililMarkPainter extends CustomPainter {
  _AkililMarkPainter({this.color = FriendColors.primary, this.coreColor = FriendColors.accent});

  final Color color;
  final Color coreColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * (5.4 / 40);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke / 2;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Open arc — same silhouette as website #i-mark
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.15,
      math.pi * 1.55,
      false,
      arcPaint,
    );

    final coreRadius = size.width * (5.4 / 40);
    final corePaint = Paint()..color = coreColor;

    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant _AkililMarkPainter old) => old.color != color || old.coreColor != coreColor;
}
