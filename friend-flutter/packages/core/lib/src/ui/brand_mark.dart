import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The Akilil mark: an open teal ring around a warm clay core.
/// Shared by both apps so the brand is drawn the same way everywhere.
class AkililMark extends StatelessWidget {
  const AkililMark({super.key, this.size = 40, this.ring = FriendColors.primary, this.core = FriendColors.accent});

  final double size;
  final Color ring;
  final Color core;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Akilil',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _MarkPainter(ring, core)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.ring, this.core);

  final Color ring;
  final Color core;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * (5.4 / 40);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.15,
      math.pi * 1.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = ring,
    );
    canvas.drawCircle(center, size.width * (5.4 / 40), Paint()..color = core);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.ring != ring || old.core != core;
}
