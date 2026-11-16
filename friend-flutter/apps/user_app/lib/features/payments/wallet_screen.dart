import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';

final _walletProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/wallet');
  return res.data ?? const <String, dynamic>{};
});

final _transactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res =
      await ref.read(dioProvider).get<Map<String, dynamic>>('/me/wallet/transactions');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/// C11 Wallet — balance hero, top-up, activity ledger.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _selectedPreset = 1;
  bool _busy = false;

  static const _presets = [
    (50000, '500'),
    (100000, '1,000'),
    (200000, '2,000'),
    (500000, '5,000'),
  ];

  int get _topupCents => _presets[_selectedPreset].$1;

  static const _ethiopicFallback = ['NotoSansEthiopic'];

  Future<void> _topUp() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
            '/wallet/topup',
            data: {'amount_cents': _topupCents},
          );
      final url = res.data?['checkout_url'] as String?;
      if (!mounted) return;

      if (url == null || url.isEmpty) {
        ref.invalidate(_walletProvider);
        ref.invalidate(_transactionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).topUp)),
        );
        return;
      }

      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(url)));
      }
      ref.invalidate(_walletProvider);
      ref.invalidate(_transactionsProvider);
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(stringsProvider).walletLoadError),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatBalance(int cents, String currency, S s) {
    final major = (cents / 100).round();
    final formatted = NumberFormat('#,###').format(major);
    if (currency == 'ETB') return formatted;
    return NumberFormat.simpleCurrency(name: currency).format(cents / 100);
  }

  String _formatTxAmount(int cents, String currency, S s, {required bool credit}) {
    final major = (cents / 100).abs();
    final formatted = NumberFormat('#,###.00').format(major);
    final prefix = credit ? '+' : '−';
    if (currency == 'ETB') return '$prefix$formatted';
    return '$prefix${NumberFormat.simpleCurrency(name: currency).format(major)}';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(_walletProvider);
    final transactions = ref.watch(_transactionsProvider);
    final s = ref.watch(stringsProvider);
    final presetLabel = s.topUpAmount('${_presets[_selectedPreset].$2} ETB');

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(
        backgroundColor: FriendColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: RefreshIndicator(
        color: FriendColors.primary,
        onRefresh: () async {
          ref.invalidate(_walletProvider);
          ref.invalidate(_transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FriendLayout.horizontal,
            0,
            FriendLayout.horizontal,
            120,
          ),
          children: [
            Text(
              s.wallet,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontFamilyFallback: _ethiopicFallback,
                fontSize: FriendTypeScale.headlineLarge,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: FriendColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            wallet.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stackTrace) => Text(
                s.walletLoadError,
                style: const TextStyle(fontFamily: 'Geist'),
              ),
              data: (w) {
                final currency = w['currency'] as String? ?? 'ETB';
                final cents = (w['balance_cents'] as num?)?.toInt() ?? 0;
                return _BalanceHero(
                  amount: _formatBalance(cents, currency, s),
                  currency: currency,
                  label: s.availableBalance,
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _presets.length; i++)
                  _AmountChip(
                    label: '${_presets[i].$2} ETB',
                    selected: _selectedPreset == i,
                    onTap: () => setState(() => _selectedPreset = i),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  s.activity,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.headlineSmall,
                    fontWeight: FontWeight.w800,
                    color: FriendColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  s.seeAll,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            transactions.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, stackTrace) => FriendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: s.couldntLoadTransactions,
                message: s.cantReach,
                ctaLabel: s.retry,
                onCta: () => ref.invalidate(_transactionsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return FriendEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: s.noActivityYet,
                    message: s.noActivityMessage,
                  );
                }
                return Column(
                  children: [
                    for (final tx in list) ...[
                      _TransactionRow(
                        tx: tx,
                        formatAmount: (c, cur, credit) =>
                            _formatTxAmount(c, cur, s, credit: credit),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: _busy ? null : _topUp,
            style: FilledButton.styleFrom(
              backgroundColor: FriendColors.accent,
              foregroundColor: FriendColors.onAccent,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            child: Text(_busy ? s.processingTopUp : presetLabel),
          ),
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.amount,
    required this.currency,
    required this.label,
  });

  final String amount;
  final String currency;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FriendColors.surface,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        border: Border.all(color: FriendColors.border),
        boxShadow: FriendElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: FriendTypeScale.caption,
              fontWeight: FontWeight.w600,
              color: FriendColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: FriendColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: FriendTypeScale.headlineSmall,
                  fontWeight: FontWeight.w700,
                  color: FriendColors.accentDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FriendColors.primaryLight : FriendColors.surface,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FriendRadii.pill),
            border: Border.all(
              color: selected ? FriendColors.primary : FriendColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: FriendTypeScale.bodySmall,
              fontWeight: FontWeight.w700,
              color: selected ? FriendColors.primaryDeep : FriendColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.formatAmount,
  });

  final Map<String, dynamic> tx;
  final String Function(int cents, String currency, bool credit) formatAmount;

  @override
  Widget build(BuildContext context) {
    final cents = (tx['amount_cents'] as num?)?.toInt() ?? 0;
    final currency = tx['currency'] as String? ?? 'ETB';
    final type = tx['type'] as String? ?? 'transaction';
    final created = DateTime.tryParse(tx['created_at'] as String? ?? '');
    final isCredit = type.contains('topup') || type.contains('refund');
    final title = tx['description'] as String? ??
        tx['title'] as String? ??
        _label(type);
    final subtitle = tx['subtitle'] as String? ??
        (created != null ? DateFormat('d MMM').format(created) : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FriendColors.surface,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        border: Border.all(color: FriendColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: FriendColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: FriendTypeScale.bodySmall,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            type.contains('free') ? 'Free' : formatAmount(cents, currency, isCredit),
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: FriendTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: isCredit ? FriendColors.primary : FriendColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _label(String type) => switch (type) {
        'topup' => 'Top-up',
        'refund' => 'Refund',
        _ => type.replaceAll('_', ' '),
      };
}