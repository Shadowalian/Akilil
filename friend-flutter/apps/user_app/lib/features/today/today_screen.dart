import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import '../auth/auth_controller.dart';
import '../brand/freud_art.dart';
import '../discovery/pillar_provider.dart';

final _nextAppointmentProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/appointments');
  final list = ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();

  final now = DateTime.now();
  final upcoming = <(DateTime, Map<String, dynamic>)>[];
  for (final appt in list) {
    if (appt['status'] == 'cancelled') continue;
    final when = DateTime.tryParse(appt['scheduled_at'] as String? ?? '');
    if (when == null || when.isBefore(now)) continue;
    upcoming.add((when, appt));
  }
  upcoming.sort((a, b) => a.$1.compareTo(b.$1));
  return upcoming.isEmpty ? null : upcoming.first.$2;
});

final _moodStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>(
      '/mood-logs/analytics',
      queryParameters: {'group_by': 'day', 'days': 30},
    );
    final data = res.data;
    final streak = (data?['streak'] as num?)?.toInt();
    if (streak != null && streak > 0) return streak;

    final series =
        (data?['series'] as List? ?? const []).cast<Map<String, dynamic>>();
    if (series.isEmpty) return 0;

    var count = 0;
    for (var i = series.length - 1; i >= 0; i--) {
      final logged = series[i]['count'] as num? ?? series[i]['avg'];
      if (logged == null || (logged is num && logged <= 0)) break;
      count++;
    }
    return count;
  } catch (_) {
    return 0;
  }
});

final _pillarCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final dio = ref.read(dioProvider);
  final slugs = const ['psychiatry', 'cooking', 'spiritual-psychiatry'];
  final counts = <String, int>{};
  for (final slug in slugs) {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/professionals',
        queryParameters: {'category': slug},
      );
      final data = res.data?['data'];
      counts[slug] = data is List ? data.length : 0;
    } catch (_) {
      counts[slug] = 0;
    }
  }
  return counts;
});

/// Home (Today) — C03: greeting, next session, mood check-in, explore support.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _ethiopicFallback = ['NotoSansEthiopic'];

  TextStyle _headline(BuildContext context, {double? size}) {
    final base = Theme.of(context).textTheme.headlineMedium;
    return (base ?? const TextStyle()).copyWith(
      fontSize: size ?? FriendTypeScale.headlineLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.7,
      height: 1.1,
      color: FriendColors.textPrimary,
      fontFamily: 'Geist',
      fontFamilyFallback: _ethiopicFallback,
    );
  }

  TextStyle _sectionTitle(BuildContext context) {
    return (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: FriendColors.textPrimary,
      fontFamily: 'Geist',
      fontFamilyFallback: _ethiopicFallback,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAppt = ref.watch(_nextAppointmentProvider);
    final streak = ref.watch(_moodStreakProvider);
    final pillarCounts = ref.watch(_pillarCountsProvider);
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeControllerProvider);
    final user = ref.watch(currentUserProvider);
    final fullName = user?.name.trim() ?? '';
    final firstName =
        fullName.isNotEmpty ? fullName.split(' ').first : 'Friend';
    final greeting = lang == AppLanguage.am
        ? s.greetingTime()
        : FriendGreeting.headline();

    return FriendTabScaffold(
      onRefresh: () async {
        ref.invalidate(_nextAppointmentProvider);
        ref.invalidate(_moodStreakProvider);
        ref.invalidate(_pillarCountsProvider);
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              FriendAvatar(
                size: 44,
                initials:
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: FriendColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                            fontFamilyFallback: _ethiopicFallback,
                          ),
                    ),
                    Text(
                      firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _headline(context, size: 26),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.search_rounded,
                tooltip: s.exploreSupport,
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(width: 8),
              _NotificationChip(
                tooltip: s.notifications,
                onPressed: () => context.go(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _NextSessionHero(nextAppt: nextAppt),
          const SizedBox(height: 28),

          _MoodCheckInSection(streak: streak, sectionTitle: _sectionTitle),
          const SizedBox(height: 28),

          _ExploreSupportSection(
            counts: pillarCounts,
            sectionTitle: _sectionTitle,
          ),
        ],
      ),
    );
  }
}

class _MoodCheckInSection extends ConsumerWidget {
  const _MoodCheckInSection({
    required this.streak,
    required this.sectionTitle,
  });

  final AsyncValue<int> streak;
  final TextStyle Function(BuildContext) sectionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.howAreYouFeeling,
                style: sectionTitle(context),
              ),
            ),
            streak.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (days) {
                if (days <= 0) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: FriendColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                    border: Border.all(
                      color: FriendColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: FriendColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.dayStreak(days),
                        style: theme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: FriendColors.accent,
                          fontFamily: 'Geist',
                          fontFamilyFallback: TodayScreen._ethiopicFallback,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        CandyCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
          child: Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _MoodPill(
                    moodIndex: i,
                    label: s.moodLabel(i),
                    onTap: () => context.go(AppRoutes.moodLog),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.moodIndex,
    required this.label,
    required this.onTap,
  });

  final int moodIndex;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              FreudArt.moodFace(mood: moodIndex, size: 44),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FriendColors.textSecondary,
                  fontFamily: 'Geist',
                  fontFamilyFallback: TodayScreen._ethiopicFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreSupportSection extends ConsumerWidget {
  const _ExploreSupportSection({
    required this.counts,
    required this.sectionTitle,
  });

  final AsyncValue<Map<String, int>> counts;
  final TextStyle Function(BuildContext) sectionTitle;

  static const _cards = [
    (
      slug: 'psychiatry',
      titleKey: _ExploreTitle.therapy,
      icon: Icons.psychology_rounded,
      tint: FriendColors.green,
    ),
    (
      slug: 'cooking',
      titleKey: _ExploreTitle.chef,
      icon: Icons.restaurant_rounded,
      tint: FriendColors.accent,
    ),
    (
      slug: 'spiritual-psychiatry',
      titleKey: _ExploreTitle.spiritual,
      icon: Icons.volunteer_activism_rounded,
      tint: FriendColors.wood,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    String titleFor(_ExploreTitle key) {
      switch (key) {
        case _ExploreTitle.therapy:
          return s.therapyLabel;
        case _ExploreTitle.chef:
          return s.chefSessionsLabel;
        case _ExploreTitle.spiritual:
          return s.spiritualCareLabel;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.sensors_rounded,
                color: FriendColors.coral,
                title: tr('Live'),
                subtitle: tr('Reflections & cook-alongs'),
                onTap: () => context.go(AppRoutes.live),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.family_restroom_rounded,
                color: FriendColors.primary,
                title: tr('Family'),
                subtitle: tr('Book for your child'),
                onTap: () => context.go(AppRoutes.family),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                s.exploreSupport,
                style: sectionTitle(context),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                s.seeAll,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FriendColors.primary,
                      fontFamily: 'Geist',
                      fontFamilyFallback: TodayScreen._ethiopicFallback,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        counts.when(
          loading: () => const _CardSpinner(),
          error: (_, _) => Column(
            children: [
              for (final card in _cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExploreCategoryCard(
                    title: titleFor(card.titleKey),
                    subtitle: null,
                    icon: card.icon,
                    tint: card.tint,
                    onTap: () {
                      ref.read(discoverPillarProvider.notifier).state =
                          card.slug;
                      context.go(AppRoutes.home);
                    },
                  ),
                ),
            ],
          ),
          data: (map) {
            return Column(
              children: [
                for (final card in _cards) ...[
                  _ExploreCategoryCard(
                    title: titleFor(card.titleKey),
                    subtitle: _subtitleFor(s, map[card.slug]),
                    icon: card.icon,
                    tint: card.tint,
                    onTap: () {
                      ref.read(discoverPillarProvider.notifier).state =
                          card.slug;
                      context.go(AppRoutes.home);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String? _subtitleFor(S s, int? count) {
    if (count == null || count <= 0) return null;
    return s.professionalsAvailable(count);
  }
}

enum _ExploreTitle { therapy, chef, spiritual }

class _ExploreCategoryCard extends StatelessWidget {
  const _ExploreCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(FriendRadii.card);
    return Material(
      color: FriendColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: FriendColors.border),
            color: FriendColors.surface,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                ),
                child: Icon(icon, size: 22, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: FriendColors.textPrimary,
                        fontFamily: 'Geist',
                        fontFamilyFallback: TodayScreen._ethiopicFallback,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.bodySmall?.copyWith(
                          color: FriendColors.textSecondary,
                          fontFamily: 'Geist',
                          fontFamilyFallback: TodayScreen._ethiopicFallback,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: FriendColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextSessionHero extends ConsumerWidget {
  const _NextSessionHero({required this.nextAppt});

  final AsyncValue<Map<String, dynamic>?> nextAppt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return nextAppt.when(
      loading: () => const _CardSpinner(),
      error: (e, st) => _QuietNote(message: s.couldntLoadPros),
      data: (appt) {
        if (appt == null) return const _NoSessionPanel();

        final when = DateTime.parse(appt['scheduled_at'] as String).toLocal();
        final proName =
            (appt['professional'] as Map<String, dynamic>?)?['name']
                    as String? ??
                tr('Akilil');
        final status = appt['status'] as String? ?? 'pending';
        final duration = appt['duration_minutes'] as int? ?? 45;
        final end = when.add(Duration(minutes: duration));
        final until = when.difference(DateTime.now());
        final hours = until.inHours;
        final mins = until.inMinutes.remainder(60).abs();
        final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
        final minsUntil = until.inMinutes;
        final canJoin = (status == 'pending' ||
                status == 'confirmed' ||
                status == 'in_progress') &&
            (priceCents == 0 ||
                (minsUntil <= 15 && minsUntil >= -(duration + 30)));

        final timeRange =
            '${trDate('h:mm a', when)} – ${trDate('h:mm a', end)}';

        return CandyCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                until.isNegative ? s.sessionReady : s.startsIn(hours, mins),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FriendColors.accent,
                      fontFamily: 'Geist',
                      fontFamilyFallback: TodayScreen._ethiopicFallback,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FriendAvatar(
                    size: 48,
                    initials:
                        personInitial(proName, 'A'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: FriendColors.textPrimary,
                                fontFamily: 'Geist',
                                fontFamilyFallback: TodayScreen._ethiopicFallback,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.videoTherapy} · $timeRange',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: FriendColors.textSecondary,
                                fontFamily: 'Geist',
                                fontFamilyFallback: TodayScreen._ethiopicFallback,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.appts),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FriendColors.textPrimary,
                        side: const BorderSide(color: FriendColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(FriendRadii.pill),
                        ),
                      ),
                      child: Text(s.reschedule),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FriendGlowButton(
                      label: s.join,
                      icon: Icons.videocam_rounded,
                      expanded: true,
                      onPressed: canJoin
                          ? () => context.go(
                                '${AppRoutes.appts}/${appt['id']}/room',
                              )
                          : () => context.go(
                                '${AppRoutes.appts}/${appt['id']}/setup',
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoSessionPanel extends ConsumerWidget {
  const _NoSessionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: FriendColors.surface,
        borderRadius: BorderRadius.circular(FriendRadii.card),
        border: Border.all(color: FriendColors.border),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.noSessionBooked,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: FriendColors.textPrimary,
                  fontFamily: 'Geist',
                  fontFamilyFallback: TodayScreen._ethiopicFallback,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            s.findListenerPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: FriendColors.textSecondary,
                  fontFamily: 'Geist',
                  fontFamilyFallback: TodayScreen._ethiopicFallback,
                ),
          ),
          const SizedBox(height: 18),
          FriendGlowButton(
            label: s.findAListener,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FriendColors.surfaceLowest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FriendColors.border),
              color: FriendColors.surfaceLowest,
            ),
            child: Icon(icon, size: 21, color: FriendColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _NotificationChip extends StatelessWidget {
  const _NotificationChip({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FriendColors.surfaceLowest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FriendColors.border),
              color: FriendColors.surfaceLowest,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 21,
              color: FriendColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSpinner extends StatelessWidget {
  const _CardSpinner();

  @override
  Widget build(BuildContext context) {
    return const CandyCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: FriendColors.textSecondary,
              fontFamily: 'Geist',
              fontFamilyFallback: TodayScreen._ethiopicFallback,
            ),
      ),
    );
  }
}

/// Compact shortcut tile on the home screen.
class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
