/// Akilil Platform — shared UI kit (23.dev polish × Higgsfield structure).
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

// ─── Atmosphere ─────────────────────────────────────────────────────────────

/// Flat Freud canvas — no candy orbs.
class FriendAtmosphere extends StatelessWidget {
  const FriendAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: FriendColors.background,
      child: SizedBox.expand(),
    );
  }
}

// ─── Page chrome ────────────────────────────────────────────────────────────

/// Editorial page header — Freud quiet hierarchy.
class FriendPageHeader extends StatelessWidget {
  const FriendPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FriendLayout.horizontal,
        8,
        FriendLayout.horizontal,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: FriendColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: FriendColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Section label used between content blocks.
class FriendSectionLabel extends StatelessWidget {
  const FriendSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: FriendColors.textPrimary,
            ),
      ),
    );
  }
}

/// Wraps tab content. Atmosphere + dock clearance live in [MainShell].
class FriendTabScaffold extends StatelessWidget {
  const FriendTabScaffold({
    super.key,
    required this.body,
    this.onRefresh,
  });

  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (onRefresh != null) {
      return RefreshIndicator(
        color: FriendColors.primary,
        onRefresh: onRefresh!,
        child: body,
      );
    }
    return body;
  }
}

/// Pushed routes — back affordance + editorial header + scroll body.
class FriendPageScaffold extends StatelessWidget {
  const FriendPageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.subtitle,
    this.trailing,
    this.showBack = true,
    this.onRefresh,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? trailing;
  final bool showBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final header = ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, FriendLayout.horizontal, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        FriendPageHeader(
          eyebrow: eyebrow,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FriendLayout.horizontal,
            0,
            FriendLayout.horizontal,
            FriendLayout.horizontal,
          ),
          child: body,
        ),
      ],
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: FriendColors.primary,
        onRefresh: onRefresh!,
        child: SingleChildScrollView(child: header),
      );
    }
    return SingleChildScrollView(child: header);
  }
}

// ─── Surfaces ───────────────────────────────────────────────────────────────

/// Tight editorial card — hairline border, optional accent stripe.
class CandyCard extends StatelessWidget {
  const CandyCard({
    super.key,
    required this.child,
    this.tint,
    this.padding,
    this.onTap,
    this.accentStripe = false,
  });

  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool accentStripe;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FriendRadii.card);
    final stripeColor = tint ?? FriendColors.primary;

    Widget body = Padding(
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );

    if (accentStripe) {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(FriendRadii.card),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: tint == null
            ? FriendColors.surface
            : Color.alphaBlend(
                tint!.withValues(alpha: 0.07),
                FriendColors.surface,
              ),
        borderRadius: radius,
        border: Border.all(
          color: FriendColors.border.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: FriendElevation.card,
      ),
      child: ClipRRect(borderRadius: radius, child: body),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

/// Back-compat alias — maps to [FriendPageHeader].
class CandyGradientHeader extends StatelessWidget {
  const CandyGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.hue,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? hue;

  @override
  Widget build(BuildContext context) {
    return FriendPageHeader(
      eyebrow: 'Akilil',
      title: title,
      subtitle: subtitle,
      trailing: action,
    );
  }
}

/// Settings / menu row inside a card group.
class FriendMenuTile extends StatelessWidget {
  const FriendMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FriendColors.primaryLight,
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                ),
                child: Icon(icon, size: 20, color: FriendColors.primaryDeep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: FriendColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: FriendColors.textMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon chip for header actions (filters, inbox).
class FriendIconChip extends StatelessWidget {
  const FriendIconChip({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: FriendColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FriendRadii.pill),
              border: Border.all(color: FriendColors.border),
            ),
            child: Icon(icon, size: 20, color: FriendColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Primary CTA — solid primary fill with one soft shadow.
/// Press compresses slightly (peak-end micro-reward). BetterHelp-grade weight.
class FriendGlowButton extends StatefulWidget {
  const FriendGlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.secondary = false,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool secondary;
  final bool showArrow;

  @override
  State<FriendGlowButton> createState() => _FriendGlowButtonState();
}

class _FriendGlowButtonState extends State<FriendGlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final secondary = widget.secondary;
    const height = 54.0;

    final child = secondary
        ? OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: FriendColors.primaryDeep,
              backgroundColor: FriendColors.surface,
              side: const BorderSide(color: FriendColors.border, width: 1.5),
              minimumSize: Size(widget.expanded ? double.infinity : 0, height),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
            ),
            child: _label(secondary: true),
          )
        : Listener(
            onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onPointerCancel:
                enabled ? (_) => setState(() => _pressed = false) : null,
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _pressed
                              ? const [
                                  FriendColors.primaryDeep,
                                  Color(0xFF0C6E8C),
                                ]
                              : const [
                                  Color(0xFF2AADCF),
                                  FriendColors.primary,
                                ],
                        )
                      : null,
                  color: enabled
                      ? null
                      : FriendColors.primary.withValues(alpha: 0.35),
                  boxShadow: enabled
                      ? (_pressed
                          ? FriendElevation.glowPressed
                          : FriendElevation.glow)
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                    splashColor: Colors.white.withValues(alpha: 0.16),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: widget.expanded ? double.infinity : 0,
                        minHeight: height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Center(child: _label(secondary: false)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: child)
        : child;
  }

  Widget _label({required bool secondary}) {
    final style = GoogleFonts.urbanist(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: secondary ? FriendColors.primaryDeep : FriendColors.onPrimary,
      height: 1.1,
    );
    final fg = secondary ? FriendColors.primaryDeep : FriendColors.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 19, color: fg),
          const SizedBox(width: 8),
        ],
        Text(widget.label, style: style),
        if (widget.showArrow) ...[
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 18, color: fg),
        ],
      ],
    );
  }
}

// ─── Phase 2 — premium components ───────────────────────────────────────────

/// Avatar — flat primary ring, no rainbow.
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 72,
    this.verified = false,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final inner = size - 4;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: FriendColors.primaryLight, width: 2),
            color: FriendColors.surface,
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: inner,
                    height: inner,
                  )
                : ColoredBox(
                    color: FriendColors.primaryLight,
                    child: Center(
                      child: Text(
                        initials ?? '?',
                        style: GoogleFonts.urbanist(
                          fontSize: inner * 0.36,
                          fontWeight: FontWeight.w700,
                          color: FriendColors.primaryDeep,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        if (verified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: const BoxDecoration(
                color: FriendColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: size * 0.16,
                color: FriendColors.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact feature tile for Today explore row.
class FriendFeatureTile extends StatelessWidget {
  const FriendFeatureTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.color = FriendColors.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: FriendGradients.cardTint(color),
              borderRadius: BorderRadius.circular(FriendRadii.small),
              border: Border.all(color: FriendColors.border),
            ),
            child: Icon(icon, size: 20, color: FriendColors.accentDeep),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: FriendColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Featured hero card with soft gradient wash.
class FriendHeroCard extends StatelessWidget {
  const FriendHeroCard({
    super.key,
    required this.child,
    this.onTap,
    this.tint = FriendColors.primary,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FriendRadii.large);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: FriendGradients.cardTint(tint),
        border: Border.all(color: FriendColors.border),
        boxShadow: FriendElevation.button,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

/// Frosted sticky bottom bar for booking CTAs.
class FriendGlassBar extends StatelessWidget {
  const FriendGlassBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: FriendColors.surface.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: FriendColors.border)),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

/// Soft search / filter bar for Discover.
class FriendSearchBar extends StatelessWidget {
  const FriendSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.trailing,
  });

  final String hint;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FriendLayout.horizontal,
        0,
        FriendLayout.horizontal,
        16,
      ),
      child: Material(
        color: FriendColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FriendRadii.pill),
              border: Border.all(color: FriendColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 20, color: FriendColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FriendColors.textMuted,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty / chips ──────────────────────────────────────────────────────────

class FriendEmptyState extends StatelessWidget {
  const FriendEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FriendColors.primaryLight,
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                border: Border.all(color: FriendColors.border),
              ),
              child: Icon(icon, size: 28, color: FriendColors.primaryDeep),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: FriendColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 22),
              FriendGlowButton(label: ctaLabel!, onPressed: onCta, icon: Icons.arrow_forward),
            ],
          ],
        ),
      ),
    );
  }
}

class FriendStatusChip extends StatelessWidget {
  const FriendStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          color: color == FriendColors.primary ? FriendColors.primaryDeep : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Floating dock nav ──────────────────────────────────────────────────────

class FriendDockItem {
  const FriendDockItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating capsule nav — pure rounded surface, no Material/Scaffold chrome.
class FriendFloatingDock extends StatelessWidget {
  const FriendFloatingDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FriendDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: FriendColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        border: Border.all(color: FriendColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: FriendColors.ink.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _DockButton(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FriendDockItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? FriendColors.primary : FriendColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? FriendColors.primaryLight.withValues(alpha: 0.55) : Colors.transparent,
          borderRadius: BorderRadius.circular(FriendRadii.pill),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 22,
              color: fg,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
                height: 1.1,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
