import 'package:friend_user/l10n/tr.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// Interactive Box Breathing Exercise (4s Inhale, 4s Hold, 4s Exhale, 4s Hold)
/// Real-time animated breathing pacer with cycle counter and somatic cues.
class BoxBreathingDialog extends StatefulWidget {
  const BoxBreathingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const BoxBreathingDialog(),
    );
  }

  @override
  State<BoxBreathingDialog> createState() => _BoxBreathingDialogState();
}

class _BoxBreathingDialogState extends State<BoxBreathingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _cycleCount = 0;
  String _phaseLabel = 'Inhale';
  String _phaseHint = tr('Breathe in slowly through the nose');
  Timer? _tickTimer;
  int _secondsInPhase = 4;

  @override
  void initState() {
    super.initState();
    // 16 seconds total box cycle (4s * 4 phases)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_onTick);

    _controller.repeat();
    _startSecondTimer();
  }

  void _startSecondTimer() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsInPhase > 1) {
          _secondsInPhase--;
        } else {
          _secondsInPhase = 4;
        }
      });
    });
  }

  void _onTick() {
    final val = _controller.value;
    String newPhase;
    String newHint;

    if (val < 0.25) {
      newPhase = 'Inhale';
      newHint = tr('Fill your lungs with cool, gentle air');
    } else if (val < 0.50) {
      newPhase = 'Hold';
      newHint = tr('Rest in stillness. Keep shoulders soft');
    } else if (val < 0.75) {
      newPhase = 'Exhale';
      newHint = tr('Release slowly through parted lips');
    } else {
      newPhase = 'Hold';
      newHint = tr('Wait peacefully for the natural breath');
    }

    if (newPhase != _phaseLabel) {
      setState(() {
        _phaseLabel = newPhase;
        _phaseHint = newHint;
        _secondsInPhase = 4;
        if (newPhase == 'Inhale') {
          _cycleCount++;
        }
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: FriendColors.surface,
          borderRadius: BorderRadius.circular(FriendRadii.large),
          border: Border.all(color: FriendColors.border),
          boxShadow: FriendElevation.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FriendColors.primaryLight,
                    borderRadius: BorderRadius.circular(FriendRadii.small),
                  ),
                  child: const Icon(
                    Icons.air_rounded,
                    color: FriendColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Box Breathing'),
                        style: friendFont(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                      Text(
                        tr('Slows your heart and calms your body'),
                        style: friendFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: FriendColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Animated Breathing Bubble
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final val = _controller.value;
                double scale;
                Color glowColor;

                if (val < 0.25) {
                  // Inhale: 0.7 -> 1.0
                  final t = val / 0.25;
                  scale = 0.75 + (0.25 * Curves.easeInOut.transform(t));
                  glowColor = FriendColors.primary;
                } else if (val < 0.50) {
                  // Hold full: 1.0
                  scale = 1.0;
                  glowColor = FriendColors.green;
                } else if (val < 0.75) {
                  // Exhale: 1.0 -> 0.75
                  final t = (val - 0.50) / 0.25;
                  scale = 1.0 - (0.25 * Curves.easeInOut.transform(t));
                  glowColor = FriendColors.accent;
                } else {
                  // Hold empty: 0.75
                  scale = 0.75;
                  glowColor = FriendColors.wood;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer soft ripple
                    Container(
                      width: 220 * scale,
                      height: 220 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor.withValues(alpha: 0.08),
                      ),
                    ),
                    // Inner ring
                    Container(
                      width: 175 * scale,
                      height: 175 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor.withValues(alpha: 0.16),
                        border: Border.all(
                          color: glowColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    // Core bubble with countdown
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            glowColor,
                            glowColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_secondsInPhase',
                              style: friendFont(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _phaseLabel.toUpperCase(),
                              style: friendFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            Text(
              _phaseHint,
              textAlign: TextAlign.center,
              style: friendFont(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FriendColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: FriendColors.background,
                borderRadius: BorderRadius.circular(FriendRadii.pill),
                border: Border.all(color: FriendColors.border),
              ),
              child: Text(
                trx('Completed cycles: $_cycleCount', 'የተጠናቀቁ ዙሮች፦ $_cycleCount'),
                style: friendFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FriendColors.primaryDeep,
                ),
              ),
            ),
            const SizedBox(height: 24),

            FriendGlowButton(
              label: tr('Done Breathing'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
