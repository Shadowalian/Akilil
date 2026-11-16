import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'live_models.dart';

/// Plays gift animations over the video as gifts arrive.
///
/// Three tiers, set per gift in the catalogue:
///   float       a sender banner and the emoji drifting up the side
///   burst       the banner plus a spray of emojis from the centre
///   fullscreen  the room dims and one large emoji takes the stage
///
/// Never intercepts touches.
class GiftEffectsLayer extends StatefulWidget {
  const GiftEffectsLayer({super.key, required this.gifts});

  final Stream<LiveFeedItem> gifts;

  @override
  State<GiftEffectsLayer> createState() => _GiftEffectsLayerState();
}

class _GiftEffectsLayerState extends State<GiftEffectsLayer> {
  static const _maxConcurrent = 6;

  final List<_Playing> _playing = [];
  StreamSubscription<LiveFeedItem>? _sub;
  int _nextLane = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.gifts.listen(_onGift);
  }

  @override
  void didUpdateWidget(GiftEffectsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gifts != widget.gifts) {
      _sub?.cancel();
      _sub = widget.gifts.listen(_onGift);
    }
  }

  void _onGift(LiveFeedItem item) {
    if (!mounted) return;
    setState(() {
      // Under a flood, drop the oldest rather than stacking without bound.
      if (_playing.length >= _maxConcurrent) _playing.removeAt(0);
      _playing.add(_Playing(UniqueKey(), item, _nextLane++ % 3));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final p in _playing)
            _GiftEffect(
              key: p.key,
              item: p.item,
              lane: p.lane,
              onDone: () {
                if (mounted) setState(() => _playing.remove(p));
              },
            ),
        ],
      ),
    );
  }
}

class _Playing {
  _Playing(this.key, this.item, this.lane);
  final Key key;
  final LiveFeedItem item;
  final int lane;
}

class _GiftEffect extends StatefulWidget {
  const _GiftEffect({super.key, required this.item, required this.lane, required this.onDone});

  final LiveFeedItem item;
  final int lane;
  final VoidCallback onDone;

  @override
  State<_GiftEffect> createState() => _GiftEffectState();
}

class _GiftEffectState extends State<_GiftEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  String get _tier => widget.item.giftAnimation;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.item.id);
    final count = switch (_tier) { 'fullscreen' => 18, 'burst' => 12, _ => 0 };
    _particles = List.generate(count, (_) => _Particle.random(rnd));
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: switch (_tier) { 'fullscreen' => 4200, 'burst' => 3200, _ => 2600 }),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_tier == 'fullscreen' && !reduceMotion) _stage(size, t),
            if (_tier == 'burst' && !reduceMotion) ..._burst(size, t),
            if (_tier == 'float' && !reduceMotion) _floater(size, t),
            _banner(size, t),
          ],
        );
      },
    );
  }

  /// "Selam sent Rose ×3" — slides in from the left, holds, fades.
  Widget _banner(Size size, double t) {
    final slide = Curves.easeOutCubic.transform((t / 0.12).clamp(0.0, 1.0));
    final fade = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
    final item = widget.item;
    final name = (item.userName ?? 'Someone').split(' ').first;

    return Positioned(
      left: 12 - (1 - slide) * 260,
      top: size.height * 0.30 + widget.lane * 58,
      child: Opacity(
        opacity: fade,
        child: Container(
          constraints: BoxConstraints(maxWidth: size.width * 0.72),
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(colors: [Color(0xE6D9924A), Color(0x99C47A33), Color(0x00C47A33)]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white24,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'sent ${item.giftName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(item.giftEmoji, style: const TextStyle(fontSize: 30)),
              if (item.quantity > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '×${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Small gift: the emoji drifts up the right edge with a gentle sway.
  Widget _floater(Size size, double t) {
    final rise = Curves.easeOut.transform(t);
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    final sway = math.sin(t * math.pi * 3) * 14;
    return Positioned(
      right: 26 + sway,
      bottom: 150 + rise * size.height * 0.42,
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: 0.7 + 0.5 * Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0)),
          child: Text(widget.item.giftEmoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }

  /// Medium gift: emojis spray outward from the centre and fall away.
  List<Widget> _burst(Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final fade = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
    final spread = Curves.easeOutCubic.transform(t);
    return [
      for (final p in _particles)
        Positioned(
          left: cx + math.cos(p.angle) * p.distance * size.width * 0.5 * spread - 18,
          top: cy + math.sin(p.angle) * p.distance * size.height * 0.3 * spread + t * t * 90 - 18,
          child: Opacity(
            opacity: fade,
            child: Transform.rotate(
              angle: p.spin * t,
              child: Text(widget.item.giftEmoji, style: TextStyle(fontSize: 22 + p.size * 22)),
            ),
          ),
        ),
    ];
  }

  /// Premium gift: dim the room, land one big emoji, scatter sparkles.
  Widget _stage(Size size, double t) {
    final appear = (t / 0.18).clamp(0.0, 1.0);
    final leave = t < 0.82 ? 0.0 : ((t - 0.82) / 0.18).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(appear) * (1 + leave * 0.6);
    final opacity = (1 - leave).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.38 * appear)),
          for (final p in _particles)
            Positioned(
              left: size.width / 2 + math.cos(p.angle) * (60 + p.distance * size.width * 0.42) - 10,
              top: size.height * 0.40 + math.sin(p.angle) * (60 + p.distance * size.height * 0.24) - 10,
              child: Opacity(
                // Each sparkle twinkles on its own phase.
                opacity: (0.5 + 0.5 * math.sin(t * math.pi * 6 + p.spin)).clamp(0.0, 1.0) * appear,
                child: Text('✨', style: TextStyle(fontSize: 12 + p.size * 16)),
              ),
            ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.item.giftEmoji,
                style: const TextStyle(fontSize: 150, shadows: [Shadow(color: Color(0xAAFFD27A), blurRadius: 60)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  const _Particle(this.angle, this.distance, this.size, this.spin);

  factory _Particle.random(math.Random r) => _Particle(
        r.nextDouble() * math.pi * 2,
        0.35 + r.nextDouble() * 0.65,
        r.nextDouble(),
        (r.nextDouble() - 0.5) * 6,
      );

  final double angle;
  final double distance;
  final double size;
  final double spin;
}

/// Hearts that float up from the like button. Call [LikeHeartsController.pop]
/// for a tap; other viewers' likes are piped in through [remoteLikes].
class LikeHeartsLayer extends StatefulWidget {
  const LikeHeartsLayer({super.key, required this.controller, this.remoteLikes});

  final LikeHeartsController controller;
  final Stream<int>? remoteLikes;

  @override
  State<LikeHeartsLayer> createState() => _LikeHeartsLayerState();
}

class LikeHeartsController extends ChangeNotifier {
  int _pending = 0;

  void pop([int count = 1]) {
    _pending += count;
    notifyListeners();
  }

  int _take() {
    final n = _pending;
    _pending = 0;
    return n;
  }
}

class _LikeHeartsLayerState extends State<LikeHeartsLayer> {
  static const _colors = [Color(0xFFE0563B), Color(0xFFD9924A), Color(0xFFFF7AA2), Color(0xFF14B3C4), Color(0xFFFFC857)];

  final List<_Heart> _hearts = [];
  final _rnd = math.Random();
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onLocal);
    _sub = widget.remoteLikes?.listen((n) => _spawn(n.clamp(1, 6)));
  }

  void _onLocal() => _spawn(widget.controller._take());

  void _spawn(int count) {
    if (!mounted || count <= 0) return;
    setState(() {
      for (var i = 0; i < count && _hearts.length < 24; i++) {
        _hearts.add(_Heart(UniqueKey(), _colors[_rnd.nextInt(_colors.length)], _rnd.nextDouble(), _rnd.nextDouble()));
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLocal);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final h in _hearts)
            TweenAnimationBuilder<double>(
              key: h.key,
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 1500 + (h.speed * 900).round()),
              onEnd: () {
                if (mounted) setState(() => _hearts.remove(h));
              },
              builder: (context, t, _) => Positioned(
                right: 18 + math.sin(t * math.pi * 2 + h.drift * 6) * 16 + h.drift * 22,
                bottom: 96 + Curves.easeOut.transform(t) * 300,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Icon(Icons.favorite_rounded, color: h.color, size: 20 + h.drift * 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Heart {
  _Heart(this.key, this.color, this.drift, this.speed);
  final Key key;
  final Color color;
  final double drift;
  final double speed;
}
