/// Akilil — hand-painted brand illustration.
///
/// Every figure here is composed geometry (discs, arcs, rounded bars) drawn in
/// the blue / yellow / wood triad. No icon fonts stretched into "art", no
/// gradients, no stock imagery.
library;

import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';

class FreudArt {
  FreudArt._();

  /// Five-step mood ramp, chosen for how each feeling reads: a soft
  /// lavender for awful, slate for low, sunny yellow for okay, fresh green
  /// for good and bright orange for great.
  static const moodColors = <Color>[
    FriendColors.lavender,
    Color(0xFF94A3B8),
    FriendColors.accent,
    FriendColors.green,
    FriendColors.orange,
  ];

  /// Light-on-deep-blue mark for the splash screen.
  static Widget welcomeHero({double size = 260}) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _WelcomeHeroPainter()),
    );
  }

  /// Onboarding illustration panel. [slide] is 0, 1 or 2.
  static Widget onboardingPanel(int slide, {double height = 260}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _OnboardingPanelPainter(slide)),
    );
  }

  /// One of five painted mood faces. [mood] is 0 (awful) to 4 (great).
  static Widget moodFace({
    required int mood,
    double size = 52,
    bool selected = false,
  }) =>
      moodFaceAt(
        valence: mood.clamp(0, 4) / 4,
        size: size,
        selected: selected,
      );

  /// Painted face anywhere on the ramp. [valence] runs 0 (awful) → 1 (great),
  /// so scales other than five steps stay expressive.
  static Widget moodFaceAt({
    required double valence,
    double size = 52,
    bool selected = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoodFacePainter(
          valence: valence.clamp(0.0, 1.0),
          selected: selected,
        ),
      ),
    );
  }

  /// Colour for a point on the mood ramp. Snaps to a ramp stop rather than
  /// blending — mixing blue into yellow only ever produces mud.
  static Color moodColorAt(double valence) {
    final step = (valence.clamp(0.0, 1.0) * (moodColors.length - 1)).round();
    return moodColors[step];
  }

  /// Quiet decorative band used behind empty states and section panels.
  static Widget panel({
    double height = 140,
    Color tint = FriendColors.primary,
    int motif = 0,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _PanelPainter(tint: tint, motif: motif)),
    );
  }
}

// ─── Shared painting helpers ────────────────────────────────────────────────

Paint _fill(Color color) => Paint()..color = color;

Paint _stroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..color = color;

void _arc(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint, {
  double start = -math.pi / 2,
  double sweep = math.pi * 2,
}) {
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius),
    start,
    sweep,
    false,
    paint,
  );
}

void _bar(Canvas canvas, Rect rect, Color color) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
    _fill(color),
  );
}

// ─── Welcome hero ───────────────────────────────────────────────────────────

class _WelcomeHeroPainter extends CustomPainter {
  const _WelcomeHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.shortestSide;

    // Two whisper-thin orbit rings.
    _arc(canvas, c, s * 0.465, _stroke(Colors.white.withValues(alpha: 0.12), 1));
    _arc(canvas, c, s * 0.375, _stroke(Colors.white.withValues(alpha: 0.09), 1));

    // Soft field behind the mark.
    canvas.drawCircle(c, s * 0.29, _fill(Colors.white.withValues(alpha: 0.07)));

    // Open brand arc — the Akilil silhouette in warm yellow.
    _arc(
      canvas,
      c,
      s * 0.29,
      _stroke(FriendColors.accent, s * 0.042),
      start: -math.pi * 0.16,
      sweep: math.pi * 1.52,
    );

    // Wood counter-arc, closing the composition from below.
    _arc(
      canvas,
      c,
      s * 0.195,
      _stroke(FriendColors.woodLight.withValues(alpha: 0.92), s * 0.024),
      start: math.pi * 0.52,
      sweep: math.pi * 0.86,
    );

    // Warm core.
    canvas.drawCircle(c, s * 0.058, _fill(FriendColors.accent));

    // Satellites resting on the outer ring.
    const angles = [-math.pi * 0.78, math.pi * 0.08, math.pi * 0.62];
    final radii = [s * 0.022, s * 0.013, s * 0.017];
    for (var i = 0; i < angles.length; i++) {
      final a = angles[i];
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (s * 0.465),
        radii[i],
        _fill(Colors.white.withValues(alpha: 0.55)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Onboarding panels ──────────────────────────────────────────────────────

class _OnboardingPanelPainter extends CustomPainter {
  const _OnboardingPanelPainter(this.slide);

  final int slide;

  static const _backgrounds = <Color>[
    FriendColors.primaryLight,
    FriendColors.greenSoft,
    Color(0xFFFFE7DA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(FriendRadii.large),
    );
    canvas.drawRRect(rrect, _fill(_backgrounds[slide % 3]));
    canvas.save();
    canvas.clipRRect(rrect);
    switch (slide % 3) {
      case 0:
        _paintHorizon(canvas, size);
      case 1:
        _paintSession(canvas, size);
      default:
        _paintGrowth(canvas, size);
    }
    canvas.restore();
  }

  /// Slide 0 — a sun rising over three layers of ground. One quiet place.
  void _paintHorizon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sun = Offset(w * 0.5, h * 0.46);
    final r = h * 0.17;

    for (var i = 0; i < 3; i++) {
      _arc(
        canvas,
        sun,
        r * (1.55 + i * 0.42),
        _stroke(FriendColors.primary.withValues(alpha: 0.26 - i * 0.06), 1.4),
        start: math.pi * 1.08,
        sweep: math.pi * 0.84,
      );
    }

    canvas.drawCircle(sun, r, _fill(FriendColors.primary));
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.20),
      r * 0.26,
      _fill(FriendColors.accent),
    );

    _bar(
      canvas,
      Rect.fromLTWH(w * 0.10, h * 0.60, w * 0.80, h * 0.035),
      FriendColors.wood.withValues(alpha: 0.75),
    );
    _bar(
      canvas,
      Rect.fromLTWH(w * 0.26, h * 0.70, w * 0.48, h * 0.028),
      FriendColors.wood.withValues(alpha: 0.5),
    );
    _bar(
      canvas,
      Rect.fromLTWH(w * 0.38, h * 0.79, w * 0.24, h * 0.022),
      FriendColors.wood.withValues(alpha: 0.3),
    );
  }

  /// Slide 1 — two session tiles, face to face.
  void _paintSession(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void tile(Rect rect, Color face, Color ink, {Color? border}) {
      final rr = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(FriendRadii.medium),
      );
      canvas.drawRRect(rr, _fill(face));
      if (border != null) {
        canvas.drawRRect(rr, _stroke(border, 1.4));
      }
      final head = Offset(rect.center.dx, rect.top + rect.height * 0.36);
      canvas.drawCircle(head, rect.height * 0.15, _fill(ink));
      final shoulders = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top + rect.height * 0.70),
        width: rect.width * 0.52,
        height: rect.height * 0.20,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: shoulders.center,
          width: shoulders.width,
          height: shoulders.height * 2,
        ),
        math.pi,
        math.pi,
        false,
        _stroke(ink, rect.height * 0.085),
      );
    }

    tile(
      Rect.fromLTWH(w * 0.14, h * 0.16, w * 0.38, h * 0.44),
      FriendColors.surface,
      FriendColors.primary.withValues(alpha: 0.35),
      border: FriendColors.primary.withValues(alpha: 0.28),
    );
    tile(
      Rect.fromLTWH(w * 0.46, h * 0.38, w * 0.40, h * 0.46),
      FriendColors.primary,
      Colors.white.withValues(alpha: 0.9),
    );

    // Live dot on the speaking tile.
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.46),
      h * 0.022,
      _fill(FriendColors.accent),
    );
  }

  /// Slide 2 — a mood trend climbing over five days.
  void _paintGrowth(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = h * 0.78;
    final slotW = w * 0.72 / 5;
    final barW = slotW * 0.42;

    const heights = [0.18, 0.30, 0.24, 0.42, 0.54];
    final colors = [
      FriendColors.wood.withValues(alpha: 0.35),
      FriendColors.primary.withValues(alpha: 0.30),
      FriendColors.primary.withValues(alpha: 0.45),
      FriendColors.primary,
      FriendColors.accent,
    ];

    for (var i = 0; i < 5; i++) {
      final cx = w * 0.14 + slotW * (i + 0.5);
      final barH = h * heights[i];
      _bar(
        canvas,
        Rect.fromLTWH(cx - barW / 2, base - barH, barW, barH),
        colors[i],
      );
    }

    _bar(
      canvas,
      Rect.fromLTWH(w * 0.10, base + h * 0.02, w * 0.80, h * 0.018),
      FriendColors.woodDeep.withValues(alpha: 0.35),
    );

    // Dotted trend line arching over the bars.
    final p0 = Offset(w * 0.18, h * 0.52);
    final p1 = Offset(w * 0.50, h * 0.10);
    final p2 = Offset(w * 0.84, h * 0.24);
    for (var i = 0; i <= 12; i++) {
      final t = i / 12;
      final u = 1 - t;
      final point = Offset(
        u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
        u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
      );
      canvas.drawCircle(
        point,
        h * 0.013,
        _fill(FriendColors.primaryDeep.withValues(alpha: 0.22 + t * 0.5)),
      );
    }
    canvas.drawCircle(p2, h * 0.032, _fill(FriendColors.accent));
  }

  @override
  bool shouldRepaint(covariant _OnboardingPanelPainter oldDelegate) =>
      oldDelegate.slide != slide;
}

// ─── Mood faces ─────────────────────────────────────────────────────────────

class _MoodFacePainter extends CustomPainter {
  const _MoodFacePainter({required this.valence, required this.selected});

  /// 0 = awful, 1 = great.
  final double valence;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final hue = FreudArt.moodColorAt(valence);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(
      c,
      r,
      _fill(selected ? hue : hue.withValues(alpha: 0.20)),
    );
    final ink = selected ? FriendColors.surface : hue;
    final line = _stroke(ink, r * 0.115);

    final eyeY = c.dy - r * 0.20;
    final eyeDx = r * 0.36;
    if (valence >= 0.95) {
      // Happy eyes — two upward arcs.
      for (final dx in [-eyeDx, eyeDx]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx + dx, eyeY + r * 0.06),
            width: r * 0.40,
            height: r * 0.34,
          ),
          math.pi,
          math.pi,
          false,
          line,
        );
      }
    } else {
      for (final dx in [-eyeDx, eyeDx]) {
        canvas.drawCircle(Offset(c.dx + dx, eyeY), r * 0.085, _fill(ink));
      }
    }

    // Worry brows on the lower half of the ramp.
    if (valence <= 0.3) {
      final tilt = r * (0.10 + (0.3 - valence) * 0.2);
      final brow = _stroke(ink, r * 0.085);
      canvas.drawLine(
        Offset(c.dx - eyeDx - r * 0.18, eyeY - r * 0.36 + tilt),
        Offset(c.dx - eyeDx + r * 0.16, eyeY - r * 0.36),
        brow,
      );
      canvas.drawLine(
        Offset(c.dx + eyeDx - r * 0.16, eyeY - r * 0.36),
        Offset(c.dx + eyeDx + r * 0.18, eyeY - r * 0.36 + tilt),
        brow,
      );
    }

    final mouthY = c.dy + r * 0.34;
    final halfW = r * 0.42;
    // Frown through flat to smile as valence rises.
    final bend = r * (valence - 0.5) * 1.68;
    final path = Path()..moveTo(c.dx - halfW, mouthY);
    if (bend.abs() < 0.5) {
      path.lineTo(c.dx + halfW, mouthY);
    } else {
      path.quadraticBezierTo(c.dx, mouthY + bend, c.dx + halfW, mouthY);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MoodFacePainter oldDelegate) =>
      oldDelegate.valence != valence || oldDelegate.selected != selected;
}

// ─── Decorative panel ───────────────────────────────────────────────────────

class _PanelPainter extends CustomPainter {
  const _PanelPainter({required this.tint, required this.motif});

  final Color tint;
  final int motif;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(FriendRadii.large),
    );
    canvas.drawRRect(
      rrect,
      _fill(
        Color.alphaBlend(
          tint.withValues(alpha: 0.12),
          FriendColors.surface,
        ),
      ),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final w = size.width;
    final h = size.height;

    if (motif == 0) {
      // Nested arcs radiating from the top-right corner.
      final origin = Offset(w * 0.92, h * 0.24);
      for (var i = 0; i < 4; i++) {
        _arc(
          canvas,
          origin,
          h * (0.22 + i * 0.16),
          _stroke(tint.withValues(alpha: 0.26 - i * 0.05), 1.6),
          start: math.pi * 0.42,
          sweep: math.pi * 0.96,
        );
      }
      canvas.drawCircle(
        origin,
        h * 0.07,
        _fill(FriendColors.accent),
      );
    } else {
      // Stacked pebbles.
      canvas.drawCircle(
        Offset(w * 0.22, h * 0.68),
        h * 0.22,
        _fill(tint.withValues(alpha: 0.22)),
      );
      canvas.drawCircle(
        Offset(w * 0.40, h * 0.42),
        h * 0.14,
        _fill(FriendColors.wood.withValues(alpha: 0.28)),
      );
      canvas.drawCircle(
        Offset(w * 0.54, h * 0.24),
        h * 0.08,
        _fill(FriendColors.accent.withValues(alpha: 0.7)),
      );
      _bar(
        canvas,
        Rect.fromLTWH(w * 0.08, h * 0.88, w * 0.60, h * 0.03),
        tint.withValues(alpha: 0.25),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PanelPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.motif != motif;
}
