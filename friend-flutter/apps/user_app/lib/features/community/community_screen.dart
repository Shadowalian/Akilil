import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../router.dart';

final _channelsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/community/channels');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

/// Mindful community — soft circle cards.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_channelsProvider);

    return FriendPageScaffold(
      eyebrow: tr('Community'),
      title: tr('Circles'),
      subtitle: tr('Rooms where nobody has to explain themselves.'),
      trailing: FriendGlowButton(
        label: tr('Vent'),
        icon: Icons.weekend_outlined,
        onPressed: () => context.push(AppRoutes.vents),
      ),
      onRefresh: () async => ref.invalidate(_channelsProvider),
      body: async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load circles",
          message: tr('Check your connection and try again.'),
          ctaLabel: tr('Retry'),
          onCta: () => ref.invalidate(_channelsProvider),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return FriendEmptyState(
              icon: Icons.groups_outlined,
              title: tr('No circles yet'),
              message:
                  tr('There are no circles right now. Your journal is a good place to write it down in the meantime.'),
            );
          }
          return Column(
            children: [
              for (final c in channels) ...[
                _ChannelTile(channel: c),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel});
  final Map<String, dynamic> channel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = channel['name'] as String? ?? tr('Circle');
    final description = channel['description'] as String?;
    final members = (channel['member_count'] as num?)?.toInt();
    final isPrivate = channel['is_private'] == true;

    return CandyCard(
      tint: FriendColors.primary,
      onTap: () => context.push('${AppRoutes.community}/${channel['id']}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FriendColors.primaryLight,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Icon(
              isPrivate ? Icons.lock_outline_rounded : Icons.forum_outlined,
              color: FriendColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (members != null) ...[
            const SizedBox(width: 10),
            FriendStatusChip(label: '$members', color: FriendColors.primary),
          ],
          const Icon(Icons.chevron_right_rounded, color: FriendColors.textMuted),
        ],
      ),
    );
  }
}
