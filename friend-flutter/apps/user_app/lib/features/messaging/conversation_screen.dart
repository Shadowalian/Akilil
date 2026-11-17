import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

/// Single conversation thread. Polls `/messages?since_id=...` every
/// 5s (Reverb is the future, see Task 8); sends via `POST /messages`.
///
/// The server expects `client_uuid` on the request so the user app can
/// safely retry without producing duplicates.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _lastId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>(
      '/conversations/${widget.conversationId}/messages',
      queryParameters: _lastId == null ? null : {'since_id': _lastId},
    );
    final list = ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    if (list.isNotEmpty) {
      setState(() {
        _messages = [..._messages, ...list];
        _lastId = list.last['id'] as int? ?? _lastId;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/conversations/${widget.conversationId}/messages',
        data: {'body': text, 'client_uuid': DateTime.now().microsecondsSinceEpoch.toString()},
      );
      final m = res.data?['data'] as Map<String, dynamic>?;
      if (m != null) {
        setState(() {
          _messages = [..._messages, m];
          _lastId = m['id'] as int? ?? _lastId;
        });
        _input.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      }
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          FriendPageHeader(
            eyebrow: tr('Messages'),
            title: tr('Conversation'),
            subtitle: tr('Private chat with your listener.'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: FriendColors.accent,
              onRefresh: _refresh,
              child: _messages.isEmpty
                  ? ListView(
                      children: [
                        FriendEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: tr('Say hi'),
                          message: tr('Start the conversation.'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return _MessageBubble(msg: m);
                      },
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: tr('Type a message'),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.msg});
  final Map<String, dynamic> msg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromMe = (msg['from_user_id'] != null) && (msg['from_current_user'] == true);
    final createdAt = DateTime.tryParse(msg['created_at'] as String? ?? '');
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: fromMe
              ? FriendColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (msg['body'] as String?) ?? '',
              style: TextStyle(color: fromMe ? Colors.white : null),
            ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  trDate('h:mm a', createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: (fromMe ? Colors.white : FriendColors.textSecondary)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
