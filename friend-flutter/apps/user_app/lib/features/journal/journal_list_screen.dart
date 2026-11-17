import 'package:friend_user/l10n/tr.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../brand/freud_art.dart';
import '../core_data/seed_data.dart';

final _journalProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/journal-entries');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

final _moodWeekProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>(
      '/mood-logs/analytics',
      queryParameters: {'group_by': 'day', 'days': 14},
    );
    return res.data ?? const {};
  } catch (_) {
    return const {};
  }
});

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  static const _ethiopicFallback = ['NotoSansEthiopic'];

  TextStyle _geist(
    BuildContext context, {
    double? size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? FriendColors.textPrimary,
      height: height,
      fontFamily: 'Geist',
      fontFamilyFallback: _ethiopicFallback,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_journalProvider);
    final moodWeek = ref.watch(_moodWeekProvider);
    final s = ref.watch(stringsProvider);

    final promptIndex =
        DateTime.now().day % SeedData.journalPrompts.length;
    final tonightPrompt =
        tr(SeedData.journalPrompts[promptIndex]['prompt'] ?? s.journalDefaultPrompt);

    return FriendTabScaffold(
      onRefresh: () async {
        ref.invalidate(_journalProvider);
        ref.invalidate(_moodWeekProvider);
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          FriendLayout.horizontal,
          12,
          FriendLayout.horizontal,
          FriendLayout.horizontal + 24,
        ),
        children: [
          _JournalHeader(
            title: s.journalScreenTitle,
            onNew: () => context.go('/journal/edit'),
            onInsights: () => context.go('/mood/analytics'),
          ),
          const SizedBox(height: 20),
          moodWeek.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (data) => _ThisWeekMoodCard(
              data: data,
              strings: s,
            ),
          ),
          const SizedBox(height: 12),
          _PromptCard(
            label: s.tonightsPrompt,
            prompt: tonightPrompt,
            onTap: () => context.go('/journal/edit'),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              s.recent,
              style: _geist(
                context,
                size: FriendTypeScale.headlineSmall,
                weight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => FriendEmptyState(
              icon: Icons.cloud_off_outlined,
              title: s.journalLoadError,
              message: s.cantReach,
              ctaLabel: s.retry,
              onCta: () => ref.invalidate(_journalProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return CandyCard(
                  child: FriendEmptyState(
                    icon: Icons.edit_note_outlined,
                    title: s.journalEmptyTitle,
                    message: s.journalEmptyMessage,
                    ctaLabel: s.newJournalEntry,
                    onCta: () => context.go('/journal/edit'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final e in list) ...[
                    _JournalEntryTile(
                      entry: e,
                      sharedLabel: _sharedLabel(e, s),
                      onTap: () => context.go('/journal/${e['id']}'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String? _sharedLabel(Map<String, dynamic> e, S s) {
    final name = e['shared_with_name'] as String? ??
        e['therapist_name'] as String? ??
        e['shared_with'] as String?;
    if (name != null && name.isNotEmpty) return s.sharedWith(name);
    if (e['shared_with_therapist'] == true) return s.sharedWithCareTeam;
    return null;
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({
    required this.title,
    required this.onNew,
    required this.onInsights,
  });

  final String title;
  final VoidCallback onNew;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Geist',
              fontFamilyFallback: JournalListScreen._ethiopicFallback,
              fontSize: FriendTypeScale.headlineLarge,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
              color: FriendColors.textPrimary,
              height: 1.05,
            ),
          ),
        ),
        FriendIconChip(
          icon: Icons.insights_outlined,
          tooltip: tr('Mood'),
          onPressed: onInsights,
        ),
        const SizedBox(width: 8),
        FriendIconChip(icon: Icons.add_rounded, tooltip: tr('New entry'), filled: true, onPressed: onNew),
      ],
    );
  }
}

class _ThisWeekMoodCard extends StatelessWidget {
  const _ThisWeekMoodCard({
    required this.data,
    required this.strings,
  });

  final Map<String, dynamic> data;
  final S strings;

  @override
  Widget build(BuildContext context) {
    final series =
        (data['series'] as List? ?? const []).cast<Map<String, dynamic>>();
    if (series.isEmpty) return const SizedBox.shrink();
    final week = series.length <= 7
        ? series
        : series.sublist(series.length - 7);
    final prior = series.length > 7
        ? series.sublist(series.length - 14, series.length - 7)
        : <Map<String, dynamic>>[];

  final weekAvgs = week
        .map((e) => (e['avg'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final priorAvgs = prior
        .map((e) => (e['avg'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

    final weekMean = weekAvgs.isEmpty
        ? null
        : weekAvgs.reduce((a, b) => a + b) / weekAvgs.length;
    final priorMean = priorAvgs.isEmpty
        ? null
        : priorAvgs.reduce((a, b) => a + b) / priorAvgs.length;

    var summary = strings.journalMoodSummary;
    if (weekMean != null) {
      if (weekMean >= 5.5) {
        summary = strings.journalMoodSummary;
      } else if (weekMean >= 4) {
        summary = strings.journalMoodSteady;
      } else if (weekMean >= 2.5) {
        summary = strings.journalMoodMixed;
      } else {
        summary = strings.journalMoodTough;
      }
    }

    int? trendPercent;
    if (weekMean != null && priorMean != null && priorMean > 0) {
      trendPercent =
          (((weekMean - priorMean) / priorMean) * 100).round().abs();
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < weekAvgs.length; i++) {
      spots.add(FlSpot(i.toDouble(), weekAvgs[i]));
    }

    return CandyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.thisWeek,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: FriendTypeScale.caption,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: FriendColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: FriendTypeScale.headlineSmall,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (trendPercent != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        strings.moodWeekTrend(trendPercent),
                        style: const TextStyle(
                          fontFamily: 'Geist Mono',
                          fontSize: FriendTypeScale.bodySmall,
                          color: FriendColors.accentDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (spots.length >= 2)
                SizedBox(
                  width: 96,
                  height: 40,
                  child: LineChart(
                    LineChartData(
                      minY: 1,
                      maxY: 7,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 2.5,
                          color: FriendColors.primary,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: FriendColors.primaryLight
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.label,
    required this.prompt,
    required this.onTap,
  });

  final String label;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.caption,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.accentDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodyLarge,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: FriendColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: FriendColors.textMuted),
        ],
      ),
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile({
    required this.entry,
    required this.onTap,
    this.sharedLabel,
  });

  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  final String? sharedLabel;

  @override
  Widget build(BuildContext context) {
    final created =
        DateTime.tryParse(entry['created_at'] as String? ?? '');
  final badge =
        created != null ? trDate('EEE', created).toUpperCase() : '—';
    final preview = (entry['body_md'] as String? ?? '')
        .split('\n')
        .first
        .trim();

    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: FriendColors.recessed,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Text(
              badge,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FriendColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry['title'] as String? ?? tr('Untitled'),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: FriendTypeScale.bodyLarge,
                          fontWeight: FontWeight.w600,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                    ),
                    if (entry['mood_at_write'] != null)
                      FreudArt.moodFaceAt(
                        valence:
                            ((entry['mood_at_write'] as int) - 1) / 6,
                        size: 22,
                      ),
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: FriendTypeScale.bodySmall,
                      height: 1.4,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
                if (sharedLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    sharedLabel!,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: FriendTypeScale.caption,
                      fontWeight: FontWeight.w600,
                      color: FriendColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}