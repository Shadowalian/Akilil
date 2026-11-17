/// Google Stitch — Akilil client chrome (SOS, progress, intent chips, CTAs).
library;

import '../util/i18n.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

TextStyle _micro(BuildContext context) =>
    GoogleFonts.inter(
      fontSize: FriendTypeScale.micro,
      height: 12 / 10,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w700,
      color: FriendColors.accent,
    );

TextStyle _labelMd(BuildContext context, {Color? color}) =>
    GoogleFonts.inter(
      fontSize: FriendTypeScale.caption,
      height: 16 / 12,
      letterSpacing: 0.24,
      fontWeight: FontWeight.w600,
      color: color ?? FriendColors.textSecondary,
    );

/// Pulsing live-status dot (waiting room, progress header).
class FriendLivePulse extends StatelessWidget {
  const FriendLivePulse({super.key, this.size = 8, this.color = FriendColors.accent});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            onEnd: () {},
            builder: (context, value, child) {
              return Opacity(
                opacity: (1 - value) * 0.75,
                child: Transform.scale(
                  scale: 1 + value * 0.8,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FriendColors.secondaryFixedDim,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

/// SOS crisis pill — error-container styling from Stitch.
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emergency_rounded, size: 15, color: FriendColors.onErrorContainer),
              const SizedBox(width: 4),
              Text(
                coreTr('SOS'),
                style: _labelMd(context, color: FriendColors.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zero-knowledge / vault assurance badge.
class FriendVaultBadge extends StatelessWidget {
  const FriendVaultBadge({
    super.key,
    this.label = 'Private and confidential',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        boxShadow: FriendElevation.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 15, color: FriendColors.accent),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: _micro(context).copyWith(color: FriendColors.accent, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

/// Segmented illuminated progress track (Step N of M).
class FriendStitchProgressTrack extends StatelessWidget {
  const FriendStitchProgressTrack({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.stepLabel,
  });

  final int step;
  final int totalSteps;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const FriendLivePulse(size: 8),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        stepLabel.toUpperCase(),
                        style: _micro(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: _labelMd(context, color: FriendColors.accent).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: FriendColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(FriendRadii.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (progress * 1000).round(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                      gradient: const LinearGradient(
                        colors: [FriendColors.accent, FriendColors.primaryContainer],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FriendColors.secondaryFixedDim.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - progress) * 1000).round().clamp(1, 1000),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic sticky app header with a privacy subline + SOS.
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + top,
          padding: EdgeInsets.fromLTRB(8, top + 4, FriendLayout.horizontal, 8),
          decoration: BoxDecoration(
            color: FriendColors.surface.withValues(alpha: 0.82),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: FriendColors.textPrimary,
                  ),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: FriendTypeScale.headlineSmall,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.18,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FriendColors.secondaryFixedDim,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coreTr('PRIVATE'),
                          style: _micro(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onSos != null) ...[
                FriendSosChip(onTap: onSos!),
                const SizedBox(width: 8),
              ],
              if (showProfileAvatar)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: FriendColors.primary,
                  ),
                  child: const Icon(Icons.person_rounded, size: 18, color: FriendColors.onPrimary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width selectable concern row (Stitch intent chip).
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
    final radius = BorderRadius.circular(FriendRadii.medium);
    return Material(
      color: FriendColors.surfaceLowest,
      elevation: 0,
      shadowColor: Colors.black12,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? LinearGradient(
                    colors: [
                      FriendColors.surfaceLowest,
                      FriendColors.recessed,
                    ],
                  )
                : null,
            boxShadow: FriendElevation.card,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? FriendColors.secondaryFixed.withValues(alpha: 0.2)
                      : FriendColors.surfaceContainerHigh,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? FriendColors.accent : FriendColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: FriendTypeScale.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: FriendTypeScale.bodySmall,
                        color: FriendColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? FriendColors.primary : FriendColors.surfaceContainerHigh,
                  boxShadow: selected ? FriendElevation.card : null,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 16, color: FriendColors.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PHQ-style radio row with point label.
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
    return Material(
      color: selected ? FriendColors.primaryContainer : FriendColors.surfaceLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? FriendColors.surfaceLowest : FriendColors.surfaceContainerHigh,
                  boxShadow: selected ? FriendElevation.card : null,
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? FriendColors.primary : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: FriendTypeScale.bodyMedium,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? FriendColors.onPrimaryContainer : FriendColors.textPrimary,
                  ),
                ),
              ),
              Text(
                pointsLabel,
                style: _micro(context).copyWith(
                  color: selected ? FriendColors.onPrimaryContainer.withValues(alpha: 0.85) : FriendColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded pill filter (modality, language).
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
    return Material(
      color: selected
          ? (roundedRect ? FriendColors.primaryContainer : FriendColors.primary)
          : FriendColors.surfaceContainer,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? (roundedRect ? FriendColors.onPrimaryContainer : FriendColors.onPrimary)
                      : FriendColors.textPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: _labelMd(
                  context,
                  color: selected
                      ? (roundedRect ? FriendColors.onPrimaryContainer : FriendColors.onPrimary)
                      : FriendColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky glass bottom bar with back + gradient primary CTA.
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: FriendColors.surface.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 8),
              child: Row(
                children: [
                  if (onBack != null)
                    Material(
                      color: FriendColors.surfaceContainer,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.west_rounded, size: 20),
                        ),
                      ),
                    ),
                  if (onBack != null) const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: primaryEnabled ? onPrimary : null,
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                        child: Ink(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(FriendRadii.pill),
                            gradient: primaryEnabled ? FriendGradients.spectrum : null,
                            color: primaryEnabled ? null : FriendColors.border,
                            boxShadow: primaryEnabled ? FriendElevation.button : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  primaryLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: FriendColors.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.east_rounded,
                                size: 18,
                                color: primaryEnabled
                                    ? FriendColors.onPrimary
                                    : FriendColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// Compact book CTA row for clinician profile sticky bar.
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: FriendColors.surface.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 8),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: FriendColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currency,
                            style: _labelMd(context, color: FriendColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        durationLabel.toUpperCase(),
                        style: _micro(context).copyWith(
                          color: FriendColors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: enabled ? onBook : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: FriendColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FriendRadii.pill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: FriendTypeScale.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
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
