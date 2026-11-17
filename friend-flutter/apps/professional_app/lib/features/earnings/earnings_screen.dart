import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

/// Earnings: what is available to withdraw, where it came from, twelve
/// weeks of bookings as bars, payouts, and a payout request.
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Earnings'))),
      body: RefreshIndicator(
        color: FriendColors.primary,
        backgroundColor: FriendColors.surface,
        onRefresh: () async {
          ref.invalidate(_earningsProvider);
          ref.invalidate(_payoutsProvider);
        },
        child: FriendContentWidth(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 8, FriendLayout.horizontal, 32),
            children: [
              earningsAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => CandyCard(child: Text(tr("Couldn't load earnings."), style: theme.textTheme.bodyMedium)),
                data: (data) => _EarningsCard(data: data),
              ),
              const SizedBox(height: FriendLayout.sectionGap),
              FriendSectionLabel(tr('Recent payouts')),
              payoutsAsync.when(
                loading: () => const SizedBox(height: 80),
                error: (e, _) => Text(tr("Couldn't load payouts."), style: theme.textTheme.bodySmall),
                data: (list) => list.isEmpty
                    ? CandyCard(child: Text(tr('No payouts yet.'), style: theme.textTheme.bodySmall))
                    : FriendListGroup(dividerIndent: 16, children: [for (final p in list) _PayoutTile(payout: p)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks how much to withdraw (prefilled with everything available) and
/// sends the request. The server checks it against the real balance.
class _RequestPayoutButton extends ConsumerStatefulWidget {
  const _RequestPayoutButton({required this.availableCents, required this.currency});

  final int availableCents;
  final String currency;

  @override
  ConsumerState<_RequestPayoutButton> createState() => _RequestPayoutButtonState();
}

class _RequestPayoutButtonState extends ConsumerState<_RequestPayoutButton> {
  bool _busy = false;

  Future<void> _request() async {
    final ctrl = TextEditingController(text: (widget.availableCents / 100).floor().toString());
    final amount = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Request payout')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: trx('Amount (${widget.currency})', 'መጠን (${widget.currency})')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, ((double.tryParse(ctrl.text.trim()) ?? 0) * 100).round()),
            child: Text(tr('Request')),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;
    setState(() => _busy = true);
    String message = tr('Payout request submitted for review.');
    var ok = true;
    try {
      await ref.read(dioProvider).post('/professional/payouts', data: {'amount_cents': amount});
    } on DioException catch (e) {
      ok = false;
      final data = e.response?.data;
      message = data is Map && data['message'] is String ? data['message'] as String : tr("Couldn't request a payout.");
    } catch (_) {
      ok = false;
      message = tr("Couldn't request a payout.");
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.invalidate(_payoutsProvider);
      ref.invalidate(_earningsProvider);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => FriendGlowButton(
        label: tr('Request payout'),
        expanded: true,
        busy: _busy,
        onPressed: widget.availableCents > 0 ? _request : null,
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const CandyCard(
        child: SizedBox(height: 200, child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))),
      );
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents = (data['total_cents'] as num? ?? 0).toInt();
    final available = (data['available_cents'] as num? ?? 0).toInt();
    final currency = data['currency'] as String? ?? 'ETB';
    final bySource = (data['by_source'] as Map?) ?? const {};
    final series = (data['series'] as List? ?? const []).cast<Map<String, dynamic>>();

    // Twelve weekly totals, oldest first.
    final weeks = List<double>.filled(12, 0);
    for (var i = 0; i < series.length; i++) {
      final bucket = (i * 12 ~/ (series.isEmpty ? 1 : series.length)).clamp(0, 11);
      weeks[bucket] += ((series[i]['cents'] as num?)?.toDouble() ?? 0) / 100;
    }
    final maxWeek = weeks.fold<double>(0, (a, b) => b > a ? b : a);

    Widget source(String label, Object? cents) => Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            Text(formatMoney(cents as num?, currency), style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary, fontFeatures: friendTabular)),
          ],
        );

    return CandyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('Available to withdraw'), style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
          const SizedBox(height: 4),
          Text(formatMoney(available, currency), style: theme.textTheme.displaySmall?.copyWith(fontFeatures: friendTabular)),
          const SizedBox(height: 4),
          Text(tr('After the platform fee'), style: theme.textTheme.labelSmall),
          const SizedBox(height: 20),
          source(tr('Sessions'), bySource['sessions']),
          const SizedBox(height: 6),
          source(tr('Groups'), bySource['groups']),
          const SizedBox(height: 6),
          source(tr('Gifts'), bySource['gifts']),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: Text(tr('Booked, last 12 weeks'), style: theme.textTheme.titleSmall)),
              Text(formatMoney(totalCents, currency), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: friendTabular)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: maxWeek <= 0
                ? Center(child: Text(tr('Nothing booked in this period yet.'), style: theme.textTheme.bodySmall))
                : BarChart(
                    BarChartData(
                      maxY: maxWeek * 1.15,
                      alignment: BarChartAlignment.spaceBetween,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < 12; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: weeks[i] <= 0 ? maxWeek * 0.02 : weeks[i],
                                width: 14,
                                color: weeks[i] <= 0 ? FriendColors.recessed : (i == 11 ? FriendColors.primary : FriendColors.primaryContainer),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(tr('12 weeks ago'), style: theme.textTheme.labelSmall),
              const Spacer(),
              Text(tr('This week'), style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 20),
          _RequestPayoutButton(availableCents: available, currency: currency),
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});
  final Map<String, dynamic> payout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cents = (payout['amount_cents'] as num? ?? 0).toInt();
    final currency = payout['currency'] as String? ?? 'ETB';
    final status = payout['status'] as String? ?? 'requested';
    final createdAt = DateTime.tryParse(payout['created_at'] as String? ?? '');
    final (label, color) = switch (status) {
      'sent' || 'succeeded' => (tr('Paid'), FriendColors.success),
      'failed' => (tr('Failed'), FriendColors.error),
      'approved' || 'processing' => (tr('Processing'), FriendColors.warning),
      _ => (tr('Requested'), FriendColors.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatMoney(cents, currency), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: friendTabular)),
                if (createdAt != null) Text(trDate('d MMM y', createdAt.toLocal()), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          FriendStatusChip(label: label, color: color),
        ],
      ),
    );
  }
}
