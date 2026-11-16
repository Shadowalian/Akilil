import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

/// Shared Stitch chrome for Akilil Pro — glass bars, SOS, wordmark, nav.
class ProStitchGlassBar extends StatelessWidget {
  const ProStitchGlassBar({
    super.key,
    required this.child,
    this.top = true,
  });

  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FriendColors.surfaceLowest.withValues(alpha: 0.85),
            boxShadow: top
                ? const [
                    BoxShadow(
                      color: Color(0x08090D16),
                      blurRadius: 12,
                      offset: Offset(0, 1),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A090D16),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
            border: top
                ? null
                : Border(top: BorderSide(color: FriendColors.border.withValues(alpha: 0.6))),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ProSosButton extends StatelessWidget {
  const ProSosButton({super.key, this.compact = false});

  final bool compact;

  void _showCrisisSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crisis support', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'If you or a client are in immediate danger, contact local emergency services. '
              'Document the incident per your clinic protocol.',
              style: TextStyle(color: FriendColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.call),
              label: const Text('Acknowledge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendColors.errorContainer,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: InkWell(
        onTap: () => _showCrisisSheet(context),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emergency, size: 16, color: FriendColors.onErrorContainer),
              const SizedBox(width: 6),
              Text(
                'SOS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: FriendColors.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProStitchCommandHeader extends StatelessWidget {
  const ProStitchCommandHeader({
    super.key,
    this.onAvatarTap,
    this.avatarInitial,
  });

  final VoidCallback? onAvatarTap;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ProStitchGlassBar(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 4, 20, 8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AKILIL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: FriendColors.secondaryFixedDim,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const ProSosButton(compact: true),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: FriendColors.primary,
                  child: Text(
                    (avatarInitial ?? 'P').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FriendColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProStitchDossierHeader extends StatelessWidget {
  const ProStitchDossierHeader({
    super.key,
    required this.onBack,
    this.avatarInitial,
  });

  final VoidCallback onBack;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ProStitchGlassBar(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 4, 20, 8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AKILIL SANCTUARY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: FriendColors.accent,
                      ),
                    ),
                    Text(
                      'Clinical Dossier',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FriendColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 14, color: FriendColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'E2EE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: FriendColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ProSosButton(compact: true),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: FriendColors.primary,
                child: Text(
                  (avatarInitial ?? 'P').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProStitchCard extends StatelessWidget {
  const ProStitchCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FriendColors.surfaceLowest,
        borderRadius: BorderRadius.circular(FriendRadii.card),
        boxShadow: elevated ? FriendElevation.button : FriendElevation.card,
      ),
      child: child,
    );
  }
}

class ProStitchMicroLabel extends StatelessWidget {
  const ProStitchMicroLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: FriendTypeScale.micro,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color ?? FriendColors.textMuted,
      ),
    );
  }
}

class ProStitchLivePill extends StatelessWidget {
  const ProStitchLivePill({super.key, required this.label, this.pulse = true});

  final String label;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FriendColors.secondaryFixed.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: FriendColors.accent,
              ),
            ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: FriendColors.accentDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class ProStitchBottomNav extends StatelessWidget {
  const ProStitchBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <(IconData, IconData, String)>[
    (Icons.schedule_outlined, Icons.schedule, 'Today'),
    (Icons.videocam_outlined, Icons.videocam, 'Sessions'),
    (Icons.explore_outlined, Icons.explore, 'Groups'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Schedule'),
    (Icons.account_circle_outlined, Icons.account_circle, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ProStitchGlassBar(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, bottom > 0 ? bottom : 12),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    selectedIcon: _items[i].$2,
                    label: _items[i].$3,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FriendColors.primary : FriendColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FriendRadii.medium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
