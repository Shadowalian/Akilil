import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import 'app_locale.dart';

/// The three Akilil pillars as a small hand of playing cards.
/// Poker proportions, hairline frame, corner pips — quiet, not toy-like.
class PillarCarousel extends ConsumerWidget {
  const PillarCarousel({
    super.key,
    required this.selectedSlug,
    required this.onSelected,
    this.height = 224,
    this.autoRevolve = false, // kept for API compat; unused
  });

  final String? selectedSlug;
  final ValueChanged<String> onSelected;
  final double height;
  final bool autoRevolve;

  static const _pips = ['A', 'K', 'Q'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final pillars = AkililPillars.all;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: FriendLayout.horizontal,
          vertical: 6,
        ),
        itemCount: pillars.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final pillar = pillars[i];
          return _PlayingCard(
            pip: _pips[i % _pips.length],
            title: s.pillarName(pillar.slug),
            subtitle: s.pillarSubtitle(pillar.slug),
            icon: pillar.icon,
            suit: pillar.color,
            selected: pillar.slug == selectedSlug,
            onTap: () => onSelected(pillar.slug),
          );
        },
      ),
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({
    required this.pip,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.suit,
    required this.selected,
    required this.onTap,
  });

  final String pip;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color suit;
  final bool selected;
  final VoidCallback onTap;

  // Poker ratio, 2.5 : 3.5
  static const double _w = 154;
  static const double _h = 216;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FriendRadii.card);
    final frame = selected
        ? FriendColors.primary.withValues(alpha: 0.30)
        : FriendColors.wood.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _w,
        height: _h,
        margin: EdgeInsets.only(top: selected ? 0 : 6, bottom: selected ? 6 : 0),
        decoration: BoxDecoration(
          color: FriendColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? FriendColors.primary : FriendColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: FriendElevation.card,
        ),
        child: Stack(
          children: [
            // Inset frame line — the printed border of a card face.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FriendRadii.card - 4),
                    border: Border.all(color: frame),
                  ),
                ),
              ),
            ),
            Positioned(top: 13, left: 13, child: _Pip(pip: pip, suit: suit)),
            Positioned(
              bottom: 13,
              right: 13,
              child: Transform.rotate(
                angle: math.pi,
                child: _Pip(pip: pip, suit: suit),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: suit.withValues(alpha: 0.10),
                        border: Border.all(
                          color: suit.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(icon, size: 21, color: suit),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: friendFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        letterSpacing: -0.3,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: friendFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.pip, required this.suit});

  final String pip;
  final Color suit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          pip,
          style: friendFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 0,
            color: suit,
          ),
        ),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 6, height: 6, color: suit),
        ),
      ],
    );
  }
}

/// Horizontal strip of restrained destination cards (More section).
class ExploreRevolveCards extends ConsumerWidget {
  const ExploreRevolveCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final items = [
      (Icons.groups_outlined, s.community, s.circlesVents, FriendColors.primary,
          '/community'),
      (Icons.edit_note_outlined, s.journal, s.privateNotes, FriendColors.accentDeep,
          '/journal'),
      (Icons.account_balance_wallet_outlined, s.wallet, s.balanceTopUps,
          FriendColors.wood, '/wallet'),
      (Icons.travel_explore_rounded, s.discover, s.threePaths,
          FriendColors.primaryDeep, '/'),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 200,
            child: Material(
              color: FriendColors.surface,
              borderRadius: BorderRadius.circular(FriendRadii.medium),
              child: InkWell(
                onTap: () => context.go(item.$5),
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FriendRadii.medium),
                    border: Border.all(color: FriendColors.border),
                    boxShadow: FriendElevation.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.$4.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(FriendRadii.small),
                          ),
                          child: Icon(item.$1, color: item.$4, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.$2,
                                style: friendFont(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                  color: FriendColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: friendFont(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: FriendColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
