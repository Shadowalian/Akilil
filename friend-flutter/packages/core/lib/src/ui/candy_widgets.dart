/// Akilil shared UI kit — v2 "Calm".
///
/// Paper canvas, white surfaces with hairlines, one action colour, quiet
/// type hierarchy. Class names from v1 are kept so screens keep compiling.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../util/i18n.dart';

// ─── Canvas ─────────────────────────────────────────────────────────────────

class FriendAtmosphere extends StatelessWidget {
  const FriendAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: FriendColors.background, child: SizedBox.expand());
  }
}

/// Centres content and caps its width on tablets and the web, so lines of
/// text and cards never stretch across a wide window.
class FriendContentWidth extends StatelessWidget {
  const FriendContentWidth({super.key, required this.child, this.maxWidth = FriendLayout.maxContentWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

// ─── Page chrome ────────────────────────────────────────────────────────────

/// Large page title with an optional supporting line.
///
/// [eyebrow] is kept for compatibility (and screen readers) but not drawn:
/// a label above every title repeats what the title already says.
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
      padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 4, FriendLayout.horizontal, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.headlineLarge),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Section heading between content blocks, with an optional trailing link.
class FriendSectionLabel extends StatelessWidget {
  const FriendSectionLabel(this.label, {super.key, this.action, this.onAction});

  final String label;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  action!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: FriendColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wraps tab content. Canvas and tab-bar clearance live in the shell.
class FriendTabScaffold extends StatelessWidget {
  const FriendTabScaffold({super.key, required this.body, this.onRefresh});

  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = FriendContentWidth(child: body);
    if (onRefresh == null) return content;
    return RefreshIndicator(
      color: FriendColors.primary,
      backgroundColor: FriendColors.surface,
      strokeWidth: 2.2,
      onRefresh: onRefresh!,
      child: content,
    );
  }
}

/// Back button used on every pushed page; matches the app bar's arrow.
class FriendBackButton extends StatelessWidget {
  const FriendBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded, size: 24, color: FriendColors.textPrimary),
    );
  }
}

/// Pushed routes — back button, large title, scrolling body.
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
    final content = FriendContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBack)
            const Padding(
              padding: EdgeInsets.fromLTRB(FriendLayout.horizontal - 12, 8, FriendLayout.horizontal, 8),
              child: Align(alignment: Alignment.centerLeft, child: FriendBackButton()),
            )
          else
            const SizedBox(height: 16),
          FriendPageHeader(eyebrow: eyebrow, title: title, subtitle: subtitle, trailing: trailing),
          Padding(
            padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 0, FriendLayout.horizontal, 40),
            child: body,
          ),
        ],
      ),
    );

    final scroll = SingleChildScrollView(
      physics: onRefresh != null
          ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
          : const BouncingScrollPhysics(),
      child: content,
    );

    final page = onRefresh != null
        ? RefreshIndicator(
            color: FriendColors.primary,
            backgroundColor: FriendColors.surface,
            strokeWidth: 2.2,
            onRefresh: onRefresh!,
            child: scroll,
          )
        : scroll;
    // Pages pushed outside the tab shell have no Material above them; without
    // one, text renders in Flutter's red debug style.
    return Material(type: MaterialType.transparency, child: SafeArea(bottom: false, child: page));
  }
}

// ─── Surfaces ───────────────────────────────────────────────────────────────

/// The standard card: white, hairline, 16 radius. [tint] gives a very light
/// wash of a colour for status cards. [accentStripe] is accepted for
/// compatibility and ignored — coloured side borders are not part of v2.
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
    final fill = tint == null
        ? FriendColors.surface
        : Color.alphaBlend(tint!.withValues(alpha: 0.06), FriendColors.surface);
    final line = tint == null
        ? FriendColors.border
        : Color.alphaBlend(tint!.withValues(alpha: 0.18), FriendColors.border);

    return _Pressable(
      onTap: onTap,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

/// Short name for new code.
typedef FriendCard = CandyCard;

/// A group of rows inside one card, separated by inset hairlines —
/// the pattern used for settings, menus and detail lists.
class FriendListGroup extends StatelessWidget {
  const FriendListGroup({super.key, required this.children, this.dividerIndent = 56});

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, indent: dividerIndent, color: FriendColors.divider));
      }
    }
    return Material(
      color: FriendColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FriendRadii.card),
        side: const BorderSide(color: FriendColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// Back-compat alias — maps to [FriendPageHeader].
class CandyGradientHeader extends StatelessWidget {
  const CandyGradientHeader({super.key, required this.title, this.subtitle, this.action, this.hue});

  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? hue;

  @override
  Widget build(BuildContext context) {
    return FriendPageHeader(eyebrow: '', title: title, subtitle: subtitle, trailing: action);
  }
}

/// Row inside a [FriendListGroup] or card: leading icon, title, subtitle,
/// chevron.
class FriendMenuTile extends StatelessWidget {
  const FriendMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = destructive ? FriendColors.error : FriendColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: destructive ? FriendColors.error : FriendColors.textSecondary),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w500)),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  (onTap != null
                      ? const Icon(Icons.chevron_right_rounded, size: 22, color: FriendColors.textMuted)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon button for page headers (filters, inbox, add).
class FriendIconChip extends StatelessWidget {
  const FriendIconChip({super.key, required this.icon, this.onPressed, this.tooltip, this.filled = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? FriendColors.ink : FriendColors.surface,
      shape: CircleBorder(side: BorderSide(color: filled ? FriendColors.ink : FriendColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: filled ? Colors.white : FriendColors.textPrimary),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Primary call to action. Solid teal, 52 high, 12 radius. [secondary]
/// gives the white outlined version. Presses scale down slightly and tick
/// the haptic engine.
class FriendGlowButton extends StatelessWidget {
  const FriendGlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.secondary = false,
    this.showArrow = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool secondary;
  final bool showArrow;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = secondary ? FriendColors.textPrimary : FriendColors.onPrimary;
    final enabled = onPressed != null && !busy;
    final content = busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: secondary ? FriendColors.primary : Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (showArrow) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 18)],
            ],
          );

    void tap() {
      HapticFeedback.selectionClick();
      onPressed?.call();
    }

    final size = Size(expanded ? double.infinity : 0, 52);
    final button = secondary
        ? OutlinedButton(
            onPressed: enabled ? tap : null,
            style: OutlinedButton.styleFrom(minimumSize: size, foregroundColor: fg),
            child: content,
          )
        : FilledButton(
            onPressed: enabled ? tap : null,
            style: FilledButton.styleFrom(
              minimumSize: size,
              disabledBackgroundColor: busy ? FriendColors.primary : null,
            ),
            child: content,
          );

    return _Pressable(onTap: enabled ? tap : null, child: button);
  }
}

/// Scales its child down a touch while pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── Identity ───────────────────────────────────────────────────────────────

/// Photo or initials. Initials sit on a soft tone picked from the name, so
/// a list of people is easy to scan without being colourful.
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({super.key, this.imageUrl, this.initials, this.size = 72, this.verified = false});

  final String? imageUrl;
  final String? initials;
  final double size;
  final bool verified;

  static const _tones = [
    (Color(0xFFE6EFEE), Color(0xFF0D5C63)),
    (Color(0xFFEFECF4), Color(0xFF55477A)),
    (Color(0xFFF7EEDF), Color(0xFF8A5517)),
    (Color(0xFFF7EAE2), Color(0xFF8F4524)),
    (Color(0xFFE5F2EA), Color(0xFF2F6B47)),
  ];

  @override
  Widget build(BuildContext context) {
    final key = (initials ?? '?').codeUnits.fold<int>(0, (a, b) => a + b);
    final tone = _tones[key % _tones.length];
    final text = (initials == null || initials!.isEmpty) ? '?' : initials!;
    final face = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(text: text, tone: tone, size: size),
              )
            : _Initials(text: text, tone: tone, size: size),
      ),
    );
    if (!verified) return face;
    final badge = (size * 0.3).clamp(14.0, 24.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(
              color: FriendColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: FriendColors.surface, width: 2),
            ),
            child: Icon(Icons.check_rounded, size: badge * 0.62, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text, required this.tone, required this.size});

  final String text;
  final (Color, Color) tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tone.$1,
      child: Center(
        child: Text(
          text.characters.take(2).toString().toUpperCase(),
          style: friendFont(fontSize: size * 0.36, fontWeight: FontWeight.w600, color: tone.$2, letterSpacing: -0.2),
        ),
      ),
    );
  }
}

// ─── Tiles ──────────────────────────────────────────────────────────────────

/// Compact tile for grids of tools.
class FriendFeatureTile extends StatelessWidget {
  const FriendFeatureTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.color = FriendColors.primary,
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
          FriendIconTile(icon: icon, color: color),
          const SizedBox(height: 14),
          Text(label, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// A rounded square holding an icon, tinted by [color].
class FriendIconTile extends StatelessWidget {
  const FriendIconTile({super.key, required this.icon, this.color = FriendColors.primary, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.1), FriendColors.surface),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Featured card: a white card with slightly more breathing room.
class FriendHeroCard extends StatelessWidget {
  const FriendHeroCard({super.key, required this.child, this.onTap, this.tint = FriendColors.primary});

  final Widget child;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return CandyCard(onTap: onTap, padding: const EdgeInsets.all(20), child: child);
  }
}

/// Sticky bottom bar for booking and checkout actions.
class FriendGlassBar extends StatelessWidget {
  const FriendGlassBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FriendColors.surface,
        border: Border(top: BorderSide(color: FriendColors.border)),
      ),
      child: SafeArea(top: false, child: FriendContentWidth(child: child)),
    );
  }
}

/// Tappable search field look-alike.
class FriendSearchBar extends StatelessWidget {
  const FriendSearchBar({super.key, required this.hint, this.onTap, this.trailing});

  final String hint;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 0, FriendLayout.horizontal, 16),
      child: Material(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: FriendColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: FriendColors.textMuted),
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

// ─── Empty states and badges ────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: FriendColors.recessed, shape: BoxShape.circle),
                child: Icon(icon, size: 26, color: FriendColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: 20),
                FriendGlowButton(label: ctaLabel!, onPressed: onCta),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status badge. Colour carries meaning: teal confirmed, clay live,
/// red problem, grey neutral.
class FriendStatusChip extends StatelessWidget {
  const FriendStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fg = Color.alphaBlend(FriendColors.ink.withValues(alpha: 0.2), color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), FriendColors.surface),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: friendFont(color: fg, fontSize: FriendTypeScale.caption, fontWeight: FontWeight.w600, height: 1.3),
      ),
    );
  }
}

// ─── Tab bar ────────────────────────────────────────────────────────────────

class FriendDockItem {
  const FriendDockItem({required this.path, required this.icon, required this.selectedIcon, required this.label});

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bottom tab bar, docked to the screen edge: white, one hairline on top,
/// the selected tab shows its filled icon in teal and an ink label.
class FriendFloatingDock extends StatelessWidget {
  const FriendFloatingDock({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<FriendDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FriendColors.surface,
        border: Border(top: BorderSide(color: FriendColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: FriendContentWidth(
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _DockButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        if (i != selectedIndex) HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.item, required this.selected, required this.onTap});

  final FriendDockItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? FriendColors.textPrimary : FriendColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightShape: BoxShape.circle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                key: ValueKey(selected),
                size: 23,
                color: selected ? FriendColors.primary : fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: friendFont(
                fontSize: FriendTypeScale.micro,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
