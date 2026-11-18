import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:core/core.dart';

/// Shared chrome for Akilil Pro, built on the core design system.

/// Top or bottom bar surface: white with one hairline.
class ProStitchGlassBar extends StatelessWidget {
  const ProStitchGlassBar({super.key, required this.child, this.top = true});

  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FriendColors.background,
        border: Border(
          bottom: top ? const BorderSide(color: FriendColors.divider) : BorderSide.none,
          top: top ? BorderSide.none : const BorderSide(color: FriendColors.border),
        ),
      ),
      child: child,
    );
  }
}

/// Emergency shortcut. Opens a sheet with the Ethiopian emergency numbers,
/// each one tap to call.
class ProSosButton extends StatelessWidget {
  const ProSosButton({super.key, this.compact = false});

  final bool compact;

  static Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showCrisisSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Widget line(String number, String label) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const FriendIconTile(icon: Icons.call_rounded, color: FriendColors.error, size: 40),
              title: Text(label, style: theme.textTheme.titleSmall),
              subtitle: Text(number, style: theme.textTheme.bodySmall?.copyWith(fontFeatures: friendTabular)),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: FriendColors.error,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _call(number),
                child: Text(tr('Call')),
              ),
            );
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Crisis support'), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  tr('If you or a client are in immediate danger, contact local emergency services. '
                      'Document the incident per your clinic protocol.'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                line('907', tr('Ambulance')),
                line('991', tr('Police')),
                line('939', tr('Fire and emergency')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => FriendSosChip(onTap: () => _showCrisisSheet(context));
}

/// Wordmark used at the top of the Pro app.
class ProWordmark extends StatelessWidget {
  const ProWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr('Akilil'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FriendColors.textPrimary),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: FriendColors.ink, borderRadius: BorderRadius.circular(5)),
          child: Text(
            'Pro',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Header on the Today tab: wordmark, SOS, your initial.
class ProStitchCommandHeader extends StatelessWidget {
  const ProStitchCommandHeader({super.key, this.onAvatarTap, this.avatarInitial});

  final VoidCallback? onAvatarTap;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ProStitchGlassBar(
      child: Padding(
        padding: EdgeInsets.fromLTRB(FriendLayout.horizontal, top + 8, FriendLayout.horizontal, 8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const ProWordmark(),
              const Spacer(),
              const ProSosButton(compact: true),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: tr('Profile'),
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: FriendAvatar(size: 34, initials: personInitial(avatarInitial, 'P')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header on a client's record: back, title, privacy note, SOS.
class ProStitchDossierHeader extends StatelessWidget {
  const ProStitchDossierHeader({super.key, required this.onBack, this.avatarInitial});

  final VoidCallback onBack;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);
    return ProStitchGlassBar(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 8, FriendLayout.horizontal, 8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              FriendBackButton(onPressed: onBack),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr('Client record'), style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 12, color: FriendColors.textMuted),
                        const SizedBox(width: 4),
                        Text(tr('Private'), style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const ProSosButton(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// The standard Pro card. Same as the client card.
class ProStitchCard extends StatelessWidget {
  const ProStitchCard({super.key, required this.child, this.padding, this.elevated = false});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CandyCard(padding: padding ?? const EdgeInsets.all(16), child: child),
    );
  }
}

/// Small grey label above a group of content. Sentence case.
class ProStitchMicroLabel extends StatelessWidget {
  const ProStitchMicroLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color ?? FriendColors.textMuted),
    );
  }
}

/// "Live" status chip.
class ProStitchLivePill extends StatelessWidget {
  const ProStitchLivePill({super.key, required this.label, this.pulse = true});

  final String label;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: FriendColors.accentLight, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[const FriendLivePulse(size: 6), const SizedBox(width: 4)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: FriendColors.live),
          ),
        ],
      ),
    );
  }
}

/// Bottom tab bar for the Pro app.
class ProStitchBottomNav extends StatelessWidget {
  const ProStitchBottomNav({super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static List<FriendDockItem> get items => [
        FriendDockItem(path: '/', icon: Icons.today_outlined, selectedIcon: Icons.today_rounded, label: tr('Today')),
        FriendDockItem(path: '/sessions', icon: Icons.videocam_outlined, selectedIcon: Icons.videocam_rounded, label: tr('Sessions')),
        FriendDockItem(path: '/groups', icon: Icons.groups_2_outlined, selectedIcon: Icons.groups_2_rounded, label: tr('Groups')),
        FriendDockItem(
          path: '/availability',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          label: tr('Schedule'),
        ),
        FriendDockItem(path: '/profile', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: tr('Profile')),
      ];

  @override
  Widget build(BuildContext context) {
    return FriendFloatingDock(items: items, selectedIndex: selectedIndex, onSelected: onSelected);
  }
}
