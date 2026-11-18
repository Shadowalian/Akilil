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

/// Home: greeting, the next session, a one-tap mood check-in, shortcuts,
/// the three kinds of support, and a quiet way to crisis help.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAppt = ref.watch(_nextAppointmentProvider);
    final streak = ref.watch(_moodStreakProvider);
    final pillarCounts = ref.watch(_pillarCountsProvider);
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeControllerProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final fullName = user?.name.trim() ?? '';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : '';
    final greeting = lang == AppLanguage.am ? s.greetingTime() : FriendGreeting.headline();

    return FriendTabScaffold(
      onRefresh: () async {
        ref.invalidate(_nextAppointmentProvider);
        ref.invalidate(_moodStreakProvider);
        ref.invalidate(_pillarCountsProvider);
      },
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 20, FriendLayout.horizontal, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trDate('EEEE, d MMMM', DateTime.now()),
                      style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        firstName.isEmpty ? greeting : '$greeting, $firstName',
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FriendIconChip(
                icon: Icons.notifications_none_rounded,
                tooltip: s.notifications,
                onPressed: () => context.go(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _NextSessionHero(nextAppt: nextAppt),
          const SizedBox(height: FriendLayout.sectionGap),
          _MoodCheckInSection(streak: streak),
          const SizedBox(height: FriendLayout.sectionGap),
          FriendSectionLabel(tr('Shortcuts')),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _QuickCard(
                icon: Icons.sensors_rounded,
                color: FriendColors.live,
                title: tr('Live'),
                subtitle: tr('Reflections & cook-alongs'),
                onTap: () => context.go(AppRoutes.live),
              ),
              _QuickCard(
                icon: Icons.groups_2_outlined,
                color: FriendColors.pillarSpiritual,
                title: tr('Group therapy'),
                subtitle: tr('Join open listening circles'),
                onTap: () => context.go(AppRoutes.groups),
              ),
              _QuickCard(
                icon: Icons.family_restroom_rounded,
                color: FriendColors.primary,
                title: tr('Family'),
                subtitle: tr('Book for your child'),
                onTap: () => context.go(AppRoutes.family),
              ),
              _QuickCard(
                icon: Icons.edit_note_rounded,
                color: FriendColors.pillarCooking,
                title: tr('Worksheets'),
                subtitle: tr('Thought records and calming exercises'),
                onTap: () => context.go(AppRoutes.worksheets),
              ),
            ],
          ),
          const SizedBox(height: FriendLayout.sectionGap),
          _ExploreSupportSection(counts: pillarCounts),
          const SizedBox(height: 24),
          _CrisisRow(onTap: () => context.go(AppRoutes.crisis)),
        ],
      ),
    );
  }
}

class _MoodCheckInSection extends ConsumerWidget {
  const _MoodCheckInSection({required this.streak});

  final AsyncValue<int> streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final days = streak.valueOrNull ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: FriendSectionLabel(s.howAreYouFeeling)),
            if (days > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  s.dayStreak(days),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: FriendColors.textMuted),
                ),
              ),
          ],
        ),
        CandyCard(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          child: Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: _MoodPill(
                    moodIndex: i,
                    label: s.moodLabel(i),
                    onTap: () => context.go(AppRoutes.moodLog),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({required this.moodIndex, required this.label, required this.onTap});

  final int moodIndex;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              FreudArt.moodFace(mood: moodIndex, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreSupportSection extends ConsumerWidget {
  const _ExploreSupportSection({required this.counts});

  final AsyncValue<Map<String, int>> counts;

  static const _slugs = ['psychiatry', 'spiritual-psychiatry', 'cooking'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final map = counts.valueOrNull ?? const <String, int>{};

    String titleFor(String slug) => switch (slug) {
          'psychiatry' => s.therapyLabel,
          'cooking' => s.chefSessionsLabel,
          _ => s.spiritualCareLabel,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendSectionLabel(
          s.exploreSupport,
          action: s.seeAll,
          onAction: () => context.go(AppRoutes.home),
        ),
        FriendListGroup(
          dividerIndent: 72,
          children: [
            for (final slug in _slugs)
              _ExploreRow(
                pillar: AkililPillars.bySlug(slug)!,
                title: titleFor(slug),
                subtitle: (map[slug] ?? 0) > 0 ? s.professionalsAvailable(map[slug]!) : null,
                onTap: () {
                  ref.read(discoverPillarProvider.notifier).state = slug;
                  context.go(AppRoutes.home);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ExploreRow extends StatelessWidget {
  const _ExploreRow({required this.pillar, required this.title, required this.subtitle, required this.onTap});

  final AkililPillar pillar;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            FriendIconTile(icon: pillar.icon, color: pillar.color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: FriendColors.textMuted),
          ],
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
    final theme = Theme.of(context);
    return nextAppt.when(
      loading: () => const _CardSpinner(),
      error: (e, st) => _QuietNote(message: s.couldntLoadPros),
      data: (appt) {
        if (appt == null) return const _NoSessionPanel();

        final when = DateTime.parse(appt['scheduled_at'] as String).toLocal();
        final proName = (appt['professional'] as Map<String, dynamic>?)?['name'] as String? ?? tr('Akilil');
        final status = appt['status'] as String? ?? 'pending';
        final duration = appt['duration_minutes'] as int? ?? 45;
        final end = when.add(Duration(minutes: duration));
        final until = when.difference(DateTime.now());
        final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
        final minsUntil = until.inMinutes;
        final canJoin = (status == 'pending' || status == 'confirmed' || status == 'in_progress') &&
            (priceCents == 0 || (minsUntil <= 15 && minsUntil >= -(duration + 30)));
        final soon = minsUntil <= 15;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FriendSectionLabel(tr('Next session')),
            CandyCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      FriendAvatar(size: 44, initials: personInitial(proName, 'A')),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${trDate('EEE d MMM', when)} · ${trDate('h:mm', when)}–${trDate('h:mm a', end)}',
                              style: theme.textTheme.bodySmall?.copyWith(fontFeatures: friendTabular),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (soon) ...[const FriendLivePulse(size: 6, color: FriendColors.success), const SizedBox(width: 6)],
                      Text(
                        until.isNegative ? s.sessionReady : s.startsIn(until.inHours, until.inMinutes.remainder(60).abs()),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: soon ? FriendColors.success : FriendColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(s.videoTherapy, style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FriendGlowButton(
                          label: tr('Manage'),
                          secondary: true,
                          expanded: true,
                          onPressed: () => context.go(AppRoutes.appts),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FriendGlowButton(
                          label: canJoin ? s.join : tr('Check camera'),
                          icon: canJoin ? Icons.videocam_rounded : null,
                          expanded: true,
                          onPressed: () => context.go(
                            canJoin ? '${AppRoutes.appts}/${appt['id']}/room' : '${AppRoutes.appts}/${appt['id']}/setup',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.noSessionBooked, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(s.findListenerPrompt, style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary)),
          const SizedBox(height: 18),
          FriendGlowButton(label: s.findAListener, onPressed: () => context.go(AppRoutes.home)),
        ],
      ),
    );
  }
}

/// Always-present, unobtrusive route to urgent help.
class _CrisisRow extends StatelessWidget {
  const _CrisisRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      onTap: onTap,
      tint: FriendColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.support_rounded, size: 22, color: FriendColors.error),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Need to talk to someone now?'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(tr('Crisis support, emergency numbers and your safety plan'), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 22, color: FriendColors.textMuted),
        ],
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
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
      ),
    );
  }
}

/// Shortcut tile on Home.
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
          FriendIconTile(icon: icon, color: color, size: 34),
          const Spacer(),
          Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
