import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

final _postsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, channelId) async {
  final dio = ref.read(dioProvider);
  final res = await dio
      .get<Map<String, dynamic>>('/community/channels/$channelId/posts');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

/// Circle feed — Freud soft post cards with avatar + like/comment row.
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key, required this.channelId});
  final String channelId;

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dioProvider).post(
        '/community/channels/${widget.channelId}/posts',
        data: {'content': content},
      );
      _controller.clear();
      ref.invalidate(_postsProvider(widget.channelId));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] as String? ?? "Couldn't post that.")
          : "Couldn't post that.";
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_postsProvider(widget.channelId));

    return FriendTabScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          const FriendPageHeader(
            eyebrow: 'Community',
            title: 'Circle',
            subtitle: 'Say something — one tap away.',
          ),
          Expanded(
            child: RefreshIndicator(
              color: FriendColors.primary,
              onRefresh: () async =>
                  ref.invalidate(_postsProvider(widget.channelId)),
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => ListView(
                  children: [
                    FriendEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: "Couldn't load posts",
                      message: 'Check your connection and try again.',
                      ctaLabel: 'Retry',
                      onCta: () =>
                          ref.invalidate(_postsProvider(widget.channelId)),
                    ),
                  ],
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return ListView(
                      children: const [
                        FriendEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'Quiet in here',
                          message: 'Be the first to say something.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      FriendLayout.horizontal,
                      0,
                      FriendLayout.horizontal,
                      12,
                    ),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PostCard(post: posts[i]),
                  );
                },
              ),
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _post,
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorMap = post['author'] as Map<String, dynamic>?;
    final author = authorMap?['name'] as String? ?? 'Someone';
    final initial = author.isNotEmpty ? author[0].toUpperCase() : '?';
    final created = DateTime.tryParse(post['created_at'] as String? ?? '');
    final likes = (post['likes_count'] as num?)?.toInt() ??
        (post['like_count'] as num?)?.toInt();
    final comments = (post['comments_count'] as num?)?.toInt() ??
        (post['comment_count'] as num?)?.toInt();

    return CandyCard(
      tint: FriendColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FriendAvatar(size: 40, initials: initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (created != null)
                      Text(
                        DateFormat('MMM d · h:mm a').format(created),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: FriendColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'] as String? ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: FriendColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                likes?.toString() ?? 'Like',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: FriendColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 18),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: FriendColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                comments?.toString() ?? 'Comment',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: FriendColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FriendLayout.horizontal,
          8,
          FriendLayout.horizontal,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Share something…',
                  filled: true,
                  fillColor: FriendColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                    borderSide: const BorderSide(color: FriendColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                    borderSide: const BorderSide(color: FriendColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                    borderSide: const BorderSide(
                      color: FriendColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: FriendColors.primary,
                foregroundColor: FriendColors.onPrimary,
              ),
              icon: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: FriendColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
