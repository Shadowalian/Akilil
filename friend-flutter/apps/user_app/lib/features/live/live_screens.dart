import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _liveListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/live-streams');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/// What is live now and what is coming up — spiritual guides and chefs.
class LiveListScreen extends ConsumerWidget {
  const LiveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_liveListProvider);
    final theme = Theme.of(context);
    return FriendPageScaffold(
      eyebrow: 'Live',
      title: 'Watch together',
      subtitle: 'Reflections with spiritual guides and cook-alongs with chefs.',
      onRefresh: () async => ref.invalidate(_liveListProvider),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => const FriendEmptyState(icon: Icons.cloud_off_outlined, title: "Couldn't load live broadcasts"),
        data: (list) => list.isEmpty
            ? const FriendEmptyState(
                icon: Icons.sensors_rounded,
                title: 'Nobody is live right now',
                message: 'Upcoming broadcasts will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(FriendLayout.horizontal),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final s = list[i];
                  final live = s['status'] == 'live';
                  final recipe = s['recipe'] as Map?;
                  final when = DateTime.tryParse((s['scheduled_at'] ?? '').toString())?.toLocal();
                  return CandyCard(
                    onTap: live ? () => context.push('/live/${s['id']}') : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FriendStatusChip(
                              label: live ? 'LIVE · ${s['viewer_count']} watching' : 'Upcoming',
                              color: live ? FriendColors.coral : FriendColors.primary,
                            ),
                            const Spacer(),
                            Text((s['category'] as Map?)?['name']?.toString() ?? '', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text((s['title'] ?? '').toString(), style: theme.textTheme.titleMedium),
                        Text(
                          '${(s['host'] as Map?)?['name'] ?? ''}'
                          '${!live && when != null ? ' · ${DateFormat('EEE MMM d, h:mm a').format(when)}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                        ),
                        if (recipe != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () => context.push('/recipes/${recipe['id']}'),
                            icon: const Icon(Icons.shopping_basket_outlined, size: 18),
                            label: Text('Get the ingredients: ${recipe['title']}'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Watching a live broadcast.
class LiveViewerScreen extends ConsumerStatefulWidget {
  const LiveViewerScreen({super.key, required this.streamId});
  final String streamId;

  @override
  ConsumerState<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends ConsumerState<LiveViewerScreen> {
  LiveFeedController? _feed;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _stream;
  List<LiveGift> _gifts = const [];
  String? _currency;
  String? _displayName;
  bool _canGift = false;
  String? _error;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    setState(() => _error = null);
    try {
      final res = await _dio.post<Map<String, dynamic>>('/live-streams/${widget.streamId}/join');
      final gifts = await _dio.get<Map<String, dynamic>>('/gifts');
      if (!mounted) return;
      final feed = LiveFeedController(dio: _dio, streamId: int.parse(widget.streamId))..start();
      setState(() {
        _session = (res.data?['session'] as Map?)?.cast<String, dynamic>();
        _stream = (res.data?['stream'] as Map?)?.cast<String, dynamic>();
        _displayName = res.data?['display_name'] as String?;
        _canGift = res.data?['can_send_gifts'] == true;
        _currency = gifts.data?['currency'] as String?;
        _gifts = ((gifts.data?['data'] as List?) ?? const [])
            .map((g) => LiveGift.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList();
        _feed = feed;
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e.response?.data, "Couldn't join the broadcast"));
    }
  }

  void _close() {
    _dio.post('/live-streams/${widget.streamId}/leave').ignore();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/live');
    }
  }

  @override
  void dispose() {
    _feed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FriendEmptyState(
          icon: Icons.sensors_off_rounded,
          title: "Can't watch right now",
          message: _error,
          ctaLabel: 'Try again',
          onCta: _join,
        ),
      );
    }
    final feed = _feed;
    final session = _session;
    if (feed == null || session == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    final stream = _stream ?? const {};
    final recipe = stream['recipe'] as Map?;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LiveRoomView(
        controller: feed,
        roomUrl: session['room_url'] as String,
        jwt: session['token'] as String?,
        displayName: _displayName,
        isHost: false,
        hostName: ((stream['host'] as Map?)?['name'] ?? 'Host').toString(),
        title: (stream['title'] ?? '').toString(),
        gifts: _gifts,
        currency: _currency,
        canSendGifts: _canGift,
        giftsDisabledReason: 'Gifts are for adults with a wallet. Ask your guardian.',
        onClose: _close,
        onTopUp: () => context.push('/wallet'),
        recipeTitle: recipe?['title']?.toString(),
        onOpenRecipe: recipe == null ? null : () => context.push('/recipes/${recipe['id']}'),
      ),
    );
  }
}
