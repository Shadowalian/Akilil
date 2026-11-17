import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../ui/candy_widgets.dart';

/// Akilil product pillars — the only practice areas in user + pro apps.
class AkililPillar {
  const AkililPillar({
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String slug;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class AkililPillars {
  AkililPillars._();

  static const spiritualPsychiatry = AkililPillar(
    slug: 'spiritual-psychiatry',
    name: 'Spiritual Psychiatry',
    subtitle: 'Faith-aware mental care',
    icon: Icons.volunteer_activism_rounded,
    color: FriendColors.pillarSpiritual,
  );

  static const psychiatry = AkililPillar(
    slug: 'psychiatry',
    name: 'Psychiatry',
    subtitle: 'Licensed clinical support',
    icon: Icons.psychology_rounded,
    color: FriendColors.pillarMind,
  );

  static const cooking = AkililPillar(
    slug: 'cooking',
    name: 'Cooking',
    subtitle: 'Live classes with chefs',
    icon: Icons.restaurant_rounded,
    color: FriendColors.pillarCooking,
  );

  static const List<AkililPillar> all = [
    spiritualPsychiatry,
    psychiatry,
    cooking,
  ];

  static AkililPillar? bySlug(String? slug) {
    if (slug == null) return null;
    for (final p in all) {
      if (p.slug == slug) return p;
    }
    return null;
  }

  static const defaultSlug = 'psychiatry';
}

/// Horizontal / stacked pillar chooser used on Discover + pro onboarding.
class FriendPillarPicker extends StatelessWidget {
  const FriendPillarPicker({
    super.key,
    required this.selectedSlug,
    required this.onSelected,
    this.compact = false,
    this.allowClear = false,
    this.nameOf,
    this.subtitleOf,
  });

  final String? selectedSlug;
  final ValueChanged<String?> onSelected;
  final bool compact;
  final bool allowClear;
  final String Function(AkililPillar pillar)? nameOf;
  final String Function(AkililPillar pillar)? subtitleOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pillar in AkililPillars.all) ...[
          _PillarCard(
            pillar: pillar,
            selected: selectedSlug == pillar.slug,
            compact: compact,
            title: nameOf?.call(pillar) ?? pillar.name,
            subtitle: subtitleOf?.call(pillar) ?? pillar.subtitle,
            onTap: () {
              if (allowClear && selectedSlug == pillar.slug) {
                onSelected(null);
              } else {
                onSelected(pillar.slug);
              }
            },
          ),
          SizedBox(height: compact ? 8 : 10),
        ],
      ],
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.pillar,
    required this.selected,
    required this.onTap,
    required this.compact,
    required this.title,
    required this.subtitle,
  });

  final AkililPillar pillar;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(FriendRadii.large);
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
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 16),
            child: Row(
              children: [
                FriendIconTile(icon: pillar.icon, color: pillar.color, size: compact ? 40 : 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? FriendColors.primary : FriendColors.surface,
                    border: Border.all(color: selected ? FriendColors.primary : FriendColors.borderStrong, width: 1.5),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
