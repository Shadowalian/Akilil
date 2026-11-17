import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

/// Earnings screen — 12-week rolling trend, recent payouts, and a
/// "request payout" button. Mirrors the admin RevenueChart widget.
final _earningsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/earnings/summary', queryParameters: {
    'days': 84, // 12 weeks
  });
  return res.data ?? const {};
});

final _payoutsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/payouts');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(_earningsProvider);
    final payoutsAsync = ref.watch(_payoutsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Earnings'))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_earningsProvider);
          ref.invalidate(_payoutsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            earningsAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(20),
                child: Text("Couldn't load earnings."))),
              data: (data) => _EarningsCard(data: data),
            ),
            const SizedBox(height: 16),
            Text(tr('Recent payouts'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            payoutsAsync.when(
              loading: () => const SizedBox(height: 80),
              error: (e, _) => const Text("Couldn't load payouts."),
              data: (list) => list.isEmpty
                  ? Card(child: Padding(padding: EdgeInsets.all(20),
                      child: Text(tr('No payouts yet.'))))
                  : Column(children: [for (final p in list) _PayoutTile(payout: p)]),
            ),
            const SizedBox(height: 16),
            const _RequestPayoutButton(),
          ],
        ),
      ),
    );
  }
}

/// Requests a fixed $50 payout. The API rejects anything under $10 and
/// anything above the available balance, so surface its message verbatim.
class _RequestPayoutButton extends ConsumerStatefulWidget {
  const _RequestPayoutButton();
  @override
  ConsumerState<_RequestPayoutButton> createState() => _RequestPayoutButtonState();
}

class _RequestPayoutButtonState extends ConsumerState<_RequestPayoutButton> {
  bool _busy = false;

  Future<void> _request() async {
    setState(() => _busy = true);
    String message = tr('Payout request submitted for review.');
    var ok = true;
    try {
      await ref.read(dioProvider).post('/professional/payouts', data: {
        'amount_cents': 5000,
      });
    } on DioException catch (e) {
      ok = false;
      final data = e.response?.data;
      message = data is Map && data['message'] is String
          ? data['message'] as String
          : "Couldn't request a payout.";
    } catch (_) {
      ok = false;
      message = "Couldn't request a payout.";
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) ref.invalidate(_payoutsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: ok ? null : FriendColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: _busy ? null : _request,
        icon: _busy
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.account_balance),
        label: Text(tr('Request payout')),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) =>
      const Card(child: SizedBox(height: 200,
          child: Center(child: CircularProgressIndicator())));
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cents = (data['total_cents'] as int? ?? 0) / 100;
    final currency = data['currency'] as String? ?? 'USD';
    final series = (data['series'] as List? ?? const []).cast<Map<String, dynamic>>();
    final spots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      final v = (series[i]['cents'] as num?)?.toDouble();
      if (v != null) spots.add(FlSpot(i.toDouble(), v / 100));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Available to withdraw'), style: Theme.of(context).textTheme.labelLarge),
            Text(formatMoney(data['available_cents'] as num?, currency),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'After platform fee · sessions ${formatMoney((data['by_source'] as Map?)?['sessions'] as num?)} · '
              'groups ${formatMoney((data['by_source'] as Map?)?['groups'] as num?)} · '
              'gifts ${formatMoney((data['by_source'] as Map?)?['gifts'] as num?)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('Booked in the last 12 weeks: ${cents.toStringAsFixed(2)} $currency',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (cents > 0)
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 2.5,
                    color: FriendColors.primary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: FriendColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});
  final Map<String, dynamic> payout;

  @override
  Widget build(BuildContext context) {
    final cents = (payout['amount_cents'] as int? ?? 0) / 100;
    final currency = payout['currency'] as String? ?? 'USD';
    final status = payout['status'] as String? ?? 'requested';
    final createdAt = DateTime.tryParse(payout['created_at'] as String? ?? '');
    return Card(
      child: ListTile(
        title: Text('${cents.toStringAsFixed(2)} $currency'),
        subtitle: Text(createdAt == null
            ? status
            : '${trDate('MMM d', createdAt)} • $status'),
        trailing: Icon(
          switch (status) {
            'sent'      => Icons.check_circle,
            'failed'    => Icons.error,
            'approved'  => Icons.hourglass_bottom,
            _           => Icons.schedule,
          },
          color: switch (status) {
            'sent'     => FriendColors.primary,
            'failed'   => FriendColors.error,
            'approved' => FriendColors.accent,
            _          => FriendColors.textSecondary,
          },
        ),
      ),
    );
  }
}