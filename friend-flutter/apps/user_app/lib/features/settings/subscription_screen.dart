import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _walletProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/wallet');
  return res.data ?? const {};
});

/// How money works on Akilil: no subscription, pay per session from your
/// wallet, and the exact refund rules the server applies.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(_walletProvider).valueOrNull;

    Widget rule(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: FriendColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );

    return FriendPageScaffold(
      eyebrow: 'Payments',
      title: 'Pricing & refunds',
      subtitle: 'No subscription and no contract. You pay for the sessions you book.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FriendHeroCard(
            tint: FriendColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wallet balance', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        wallet == null ? '—' : formatMoney(wallet['balance_cents'] as num?, wallet['currency'] as String?),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton(onPressed: () => context.push('/wallet'), child: const Text('Top up')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('What you pay for', style: theme.textTheme.titleMedium),
          rule(Icons.person_rounded, 'One-to-one sessions',
              "Each professional sets their own price, shown on their profile before you book. It's paid from your wallet when you book."),
          rule(Icons.favorite_rounded, 'Couples & family sessions',
              'Can be priced differently from individual sessions. One person pays; everyone invited joins free.'),
          rule(Icons.groups_rounded, 'Groups & cooking classes',
              'You pay per meeting, when you reserve your seat.'),
          rule(Icons.card_giftcard_rounded, 'Live gifts',
              'Optional, adults only, and not refundable. Most of each gift goes to the host.'),
          const SizedBox(height: 12),
          Text('Refunds', style: theme.textTheme.titleMedium),
          rule(Icons.check_circle_outline_rounded, '24 hours or more before',
              'Cancel and get everything back to your wallet.'),
          rule(Icons.timelapse_rounded, 'Between 24 and 2 hours before', 'You get half back.'),
          rule(Icons.block_rounded, 'Less than 2 hours before', 'No refund. The professional had kept that time for you.'),
          rule(Icons.verified_user_outlined, 'If the professional cancels', 'You always get everything back.'),
          rule(Icons.groups_2_outlined, 'Group seats',
              'Full refund if you cancel 24 hours ahead, or if the host cancels the meeting.'),
          const SizedBox(height: 12),
          Text(
            'Children and teens never pay. A parent or guardian books and pays from their own account.',
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
