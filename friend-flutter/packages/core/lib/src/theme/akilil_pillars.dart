import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

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
    color: FriendColors.wood,
  );

  static const psychiatry = AkililPillar(
    slug: 'psychiatry',
    name: 'Psychiatry',
    subtitle: 'Licensed clinical support',
    icon: Icons.psychology_rounded,
    color: FriendColors.green,
  );

  static const cooking = AkililPillar(
    slug: 'cooking',
    name: 'Cooking',
    subtitle: 'Live classes with chefs',
    icon: Icons.restaurant_rounded,
    color: FriendColors.accent,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.large),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FriendRadii.large),
            gradient: selected
                ? FriendGradients.cardTint(pillar.color)
                : null,
            color: selected ? null : FriendColors.surface.withValues(alpha: 0.9),
            border: Border.all(
              color: selected
                  ? pillar.color.withValues(alpha: 0.55)
                  : FriendColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? FriendElevation.card : null,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 40 : 46,
                height: compact ? 40 : 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                  gradient: FriendGradients.cardTint(pillar.color),
                  border: Border.all(color: FriendColors.border),
                ),
                child: Icon(pillar.icon, color: pillar.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? FriendColors.primaryDeep : FriendColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
