import 'package:friend_user/l10n/tr.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import 'care_team.dart';

final _conversationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/conversations');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/// Opens (or creates) the 1:1 thread with a professional you have booked.
Future<void> openConversationWith(BuildContext context, WidgetRef ref, int userId) async {
  try {
    final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
      '/conversations',
      data: {'participant_user_id': userId},
    );
    if (context.mounted) context.push('/messages/${res.data?['id']}');
  } on DioException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e.response?.data))));
    }
  }
}

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationsProvider);
    final team = ref.watch(careTeamProvider).valueOrNull ?? const [];
    final me = ref.watch(currentUserProvider)?.id;
    final theme = Theme.of(context);

    return FriendPageScaffold(
      eyebrow: tr('Messages'),
      title: tr('Your conversations'),
      subtitle: tr('Message the professionals you have booked. Replies come during their working hours — this is not for emergencies.'),
      onRefresh: () async {
        ref.invalidate(_conversationsProvider);
        ref.invalidate(careTeamProvider);
      },
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load messages",
          ctaLabel: tr('Try again'),
          onCta: () => ref.invalidate(_conversationsProvider),
        ),
        data: (list) {
          final withThread = <int>{
            for (final c in list)
              for (final p in (c['participants'] as List? ?? const []))
                if ((p['id'] as num?)?.toInt() != me) (p['id'] as num).toInt(),
          };
          final startable = team.where((t) => !withThread.contains(t['user_id'])).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (list.isEmpty && team.isEmpty)
                FriendEmptyState(
                  icon: Icons.forum_outlined,
                  title: tr('No conversations yet'),
                  message: tr('Once you book a session you can message that professional here.'),
                  ctaLabel: tr('Find someone'),
                  onCta: () => context.go('/'),
                ),
              for (final c in list) _ThreadTile(conversation: c, me: me),
              if (startable.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(tr('Start a conversation'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final t in startable)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: FriendAvatar(initials: personInitial(t['name'] as String?), size: 40),
                      title: Text('${t['name']}'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => openConversationWith(context, ref, t['user_id'] as int),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.conversation, required this.me});
  final Map<String, dynamic> conversation;
  final int? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final others = (conversation['participants'] as List? ?? const [])
        .where((p) => (p['id'] as num?)?.toInt() != me)
        .map((p) => (p['name'] ?? '').toString())
        .toList();
    final name = (conversation['title'] as String?)?.isNotEmpty == true
        ? conversation['title'] as String
        : (others.isEmpty ? 'Conversation' : others.join(', '));
    final last = conversation['last_message'] as Map?;
    final unread = (conversation['unread_count'] as num?)?.toInt() ?? 0;
    final at = DateTime.tryParse('${last?['created_at'] ?? conversation['last_message_at']}')?.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CandyCard(
        onTap: () => context.push('/messages/${conversation['id']}'),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            FriendAvatar(initials: personInitial(name), size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    (last?['preview'] ?? tr('Say hello')).toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: unread > 0 ? FriendColors.textPrimary : FriendColors.textSecondary,
                      fontWeight: unread > 0 ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (at != null)
                  Text(
                    DateTime.now().difference(at).inHours < 24 ? trDate('h:mm a', at) : trDate('MMM d', at),
                    style: theme.textTheme.labelSmall?.copyWith(color: FriendColors.textMuted),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: FriendColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
