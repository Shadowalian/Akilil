import 'package:friend_user/l10n/tr.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

/// Mood analytics — 30-day rolling average. Server returns one row
/// per day; we plot a line. If less than 7 days of data, the chart
/// still renders with the available points.
final _moodAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/mood-logs/analytics', queryParameters: {
    'group_by': 'day',
    'days': 30,
  });
  return res.data ?? const {};
});

class MoodAnalyticsScreen extends ConsumerWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_moodAnalyticsProvider);

    return FriendPageScaffold(
      eyebrow: tr('Insights'),
      title: tr('Mood trends'),
      subtitle: tr('Trends over weeks, not days, are what matter.'),
      onRefresh: () async => ref.invalidate(_moodAnalyticsProvider),
      body: async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load analytics",
          message: tr('Check your connection and try again.'),
          ctaLabel: tr('Retry'),
          onCta: () => ref.invalidate(_moodAnalyticsProvider),
        ),
        data: (data) {
          final series = (data['series'] as List? ?? const []).cast<Map<String, dynamic>>();
          if (series.isEmpty) {
            return FriendEmptyState(
              icon: Icons.show_chart,
              title: tr('Log a few moods to see trends'),
              message: tr('Your chart will appear after a few check-ins.'),
            );
          }
          final spots = <FlSpot>[];
          for (var i = 0; i < series.length; i++) {
            final v = (series[i]['avg'] as num?)?.toDouble();
            if (v != null) spots.add(FlSpot(i.toDouble(), v));
          }
          final avg = (data['avg'] as num?)?.toDouble() ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                trx('Average (30 days): ${avg.toStringAsFixed(1)} / 7', 'የ30 ቀን አማካይ፦ ${avg.toStringAsFixed(1)} / 7'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: LineChart(LineChartData(
                  minY: 1,
                  maxY: 7,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: FriendColors.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: FriendColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (series.length / 5).clamp(1, 30).toDouble(),
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= series.length) {
                            return const SizedBox.shrink();
                          }
                          final d = DateTime.tryParse(series[i]['date'] as String? ?? '');
                          return Text(
                            d == null ? '' : trDate('M/d', d),
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ],
          );
        },
      ),
    );
  }
}
