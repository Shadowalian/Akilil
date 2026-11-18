/// Flow components: progress, choice rows, questionnaire options, filter
/// pills and sticky action bars. v2 "Calm" — see design_tokens.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../util/i18n.dart';

TextStyle _caption({Color? color, FontWeight weight = FontWeight.w500}) => friendFont(
      fontSize: FriendTypeScale.caption,
      height: 1.3,
      fontWeight: weight,
      color: color ?? FriendColors.textSecondary,
    );

/// Live status dot that breathes slowly.
class FriendLivePulse extends StatefulWidget {
  const FriendLivePulse({super.key, this.size = 8, this.color = FriendColors.live});

  final double size;
  final Color color;

  @override
  State<FriendLivePulse> createState() => _FriendLivePulseState();
}

class _FriendLivePulseState extends State<FriendLivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: s + s * t,
                  height: s + s * t,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
                ),
              ),
              Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
            ],
          );
        },
      ),
    );
  }
}

/// Emergency shortcut shown in headers.
class FriendSosChip extends StatelessWidget {
  const FriendSosChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendColors.errorContainer,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emergency_rounded, size: 15, color: FriendColors.error),
              const SizedBox(width: 6),
              Text(coreTr('SOS'), style: _caption(color: FriendColors.error, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy reassurance line.
class FriendVaultBadge extends StatelessWidget {
  const FriendVaultBadge({super.key, this.label = 'Private and confidential'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 14, color: FriendColors.textMuted),
        const SizedBox(width: 6),
        Flexible(child: Text(coreTr(label), style: _caption(color: FriendColors.textMuted))),
      ],
    );
  }
}

/// Step progress for multi-step flows: a thin bar and "Step 2 of 5".
class FriendStitchProgressTrack extends StatelessWidget {
  const FriendStitchProgressTrack({super.key, required this.step, required this.totalSteps, required this.stepLabel});

  final int step;
  final int totalSteps;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final progress = ((step + 1) / totalSteps).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(stepLabel, style: _caption(color: FriendColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                color: FriendColors.primary,
                backgroundColor: FriendColors.recessed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header for private rooms: title, "Private" line, optional SOS.
class FriendStitchGlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const FriendStitchGlassHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onSos,
    this.showProfileAvatar = true,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSos;
  final bool showProfileAvatar;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: preferredSize.height + top,
      padding: EdgeInsets.fromLTRB(12, top + 8, FriendLayout.horizontal, 8),
      decoration: const BoxDecoration(
        color: FriendColors.background,
        border: Border(bottom: BorderSide(color: FriendColors.divider)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, size: 22))
          else
            const SizedBox(width: 8),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 12, color: FriendColors.textMuted),
                    const SizedBox(width: 4),
                    Text(coreTr('Private'), style: _caption(color: FriendColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (onSos != null) FriendSosChip(onTap: onSos!),
        ],
      ),
    );
  }
}

/// Full-width selectable row with icon, title and subtitle.
class FriendIntentChip extends StatelessWidget {
  const FriendIntentChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(FriendRadii.medium);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? FriendColors.primaryLight : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? FriendColors.primary : FriendColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? FriendColors.primary : FriendColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _CheckDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? FriendColors.primary : FriendColors.surface,
        border: Border.all(color: selected ? FriendColors.primary : FriendColors.borderStrong, width: 1.5),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}

/// Questionnaire answer row with its score.
class FriendPhqRadioOption extends StatelessWidget {
  const FriendPhqRadioOption({
    super.key,
    required this.label,
    required this.pointsLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String pointsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FriendRadii.medium);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? FriendColors.primaryLight : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? FriendColors.primary : FriendColors.border),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? FriendColors.primary : FriendColors.borderStrong,
                      width: selected ? 6 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: friendFont(
                      fontSize: FriendTypeScale.bodyMedium,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                ),
                Text(pointsLabel, style: _caption(color: FriendColors.textMuted).copyWith(fontFeatures: friendTabular)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter pill. Selected pills turn ink; unselected are white with a line.
class FriendStitchFilterPill extends StatelessWidget {
  const FriendStitchFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.roundedRect = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool roundedRect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(roundedRect ? FriendRadii.medium : FriendRadii.pill);
    final fg = selected ? Colors.white : FriendColors.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? FriendColors.selected : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? FriendColors.selected : FriendColors.borderStrong),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                Text(label, style: friendFont(fontSize: 13, fontWeight: FontWeight.w500, color: fg, height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky bottom bar with an optional back button and the primary action.
class FriendStitchStickyBar extends StatelessWidget {
  const FriendStitchStickyBar({
    super.key,
    this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryEnabled = true,
  });

  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FriendColors.background,
        border: Border(top: BorderSide(color: FriendColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FriendLayout.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 12),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(52, 52)),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: primaryEnabled && onPrimary != null
                          ? () {
                              HapticFeedback.selectionClick();
                              onPrimary!();
                            }
                          : null,
                      child: Text(primaryLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Price, duration and the book button for a professional's profile.
class FriendStitchBookBar extends StatelessWidget {
  const FriendStitchBookBar({
    super.key,
    required this.amount,
    required this.currency,
    required this.durationLabel,
    required this.buttonLabel,
    required this.onBook,
    this.enabled = true,
  });

  final String amount;
  final String currency;
  final String durationLabel;
  final String buttonLabel;
  final VoidCallback? onBook;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FriendColors.surface,
        border: Border(top: BorderSide(color: FriendColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FriendLayout.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            amount,
                            style: friendFont(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: FriendColors.textPrimary,
                              fontFeatures: friendTabular,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(currency, style: _caption()),
                        ],
                      ),
                      Text(durationLabel, style: _caption(color: FriendColors.textMuted)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: enabled ? onBook : null,
                      child: Text(buttonLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
