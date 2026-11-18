import 'package:friend_user/l10n/tr.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _clientGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/therapy-groups',
    queryParameters: {'discover': true},
  );
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

class ClientGroupsScreen extends ConsumerWidget {
  const ClientGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientGroupsProvider);
    return FriendTabScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(FriendLayout.horizontal - 12, 8, FriendLayout.horizontal, 8),
            child: Align(alignment: Alignment.centerLeft, child: FriendBackButton()),
          ),
          FriendPageHeader(
            eyebrow: tr('Together'),
            title: tr('Group therapy'),
            subtitle: tr('Join open groups and meet when the host goes live.'),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => FriendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: tr("Couldn't load groups"),
                ctaLabel: tr('Try again'),
                onCta: () => ref.invalidate(_clientGroupsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return FriendEmptyState(
                    icon: Icons.groups_outlined,
                    title: tr('No open groups yet'),
                    message: tr('Listeners can create open groups for you to join.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_clientGroupsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(FriendLayout.horizontal),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final g = list[i];
                      final isMember = g['is_member'] == true;
                      return CandyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['title'] as String? ?? tr('Group'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((g['description'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 6),
                              Text(
                                g['description'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: FriendColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  trx('${g['member_count'] ?? 0} members', '${g['member_count'] ?? 0} አባላት'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const Spacer(),
                                if (isMember)
                                  FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                    child: Text(tr('Open')),
                                    onPressed: () =>
                                        context.go('/groups/${g['id']}'),
                                  )
                                else
                                  FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                    child: Text(tr('Join group')),
                                    onPressed: () async {
                                      try {
                                        final dio = ref.read(dioProvider);
                                        await dio.post(
                                          '/therapy-groups/${g['id']}/join',
                                        );
                                        ref.invalidate(_clientGroupsProvider);
                                        if (!context.mounted) return;
                                        context.go('/groups/${g['id']}');
                                      } on DioException catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.response?.data?['message'] ??
                                                  tr('Join failed'),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClientGroupDetailScreen extends ConsumerStatefulWidget {
  const ClientGroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<ClientGroupDetailScreen> createState() =>
      _ClientGroupDetailScreenState();
}

class _ClientGroupDetailScreenState
    extends ConsumerState<ClientGroupDetailScreen> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _meetings = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final g =
          await dio.get<Map<String, dynamic>>('/therapy-groups/${widget.groupId}');
      final m = await dio.get<Map<String, dynamic>>(
        '/therapy-groups/${widget.groupId}/meetings',
      );
      if (!mounted) return;
      setState(() {
        _group = (g.data?['group'] as Map<String, dynamic>?) ?? g.data;
        _meetings = ((m.data?['data'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _post(String path, String ok) async {
    try {
      await ref.read(dioProvider).post(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 402) {
        context.push('/wallet');
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e.response?.data))));
    }
  }

  /// Reserve → (cooking: confirm ingredients) → join when the host is live.
  Widget _meetingAction(Map<String, dynamic> m) {
    final seat = m['my_seat'] as Map?;
    final hasSeat = seat?['status'] == 'reserved';
    final price = (m['price_cents'] as num?)?.toInt() ?? 0;
    final recipe = m['recipe'] as Map?;
    final status = m['status'] as String? ?? '';
    if (status != 'scheduled' && status != 'live') {
      return Text(status, style: Theme.of(context).textTheme.bodySmall);
    }
    if (!hasSeat && price > 0) {
      return FilledButton(
        onPressed: () => _post('/therapy-group-meetings/${m['id']}/reserve', 'Seat reserved'),
        child: Text(trx('Reserve · ${formatMoney(price, m['currency'] as String?)}', 'ቦታ ይያዙ · ${formatMoney(price, m['currency'] as String?)}')),
      );
    }
    if (recipe != null && seat?['ingredients_confirmed'] != true) {
      return FilledButton.tonal(
        onPressed: () async {
          if (!hasSeat) await _post('/therapy-group-meetings/${m['id']}/reserve', 'Seat reserved');
          if (!mounted) return;
          await context.push('/recipes/${recipe['id']}?meeting=${m['id']}');
          _load();
        },
        child: Text(tr('Ingredients')),
      );
    }
    if (status == 'live') {
      return FilledButton(
        onPressed: () => context.go('/groups/meetings/${m['id']}/join'),
        child: Text(tr('Join')),
      );
    }
    return Text(hasSeat ? 'Seat reserved' : tr('Scheduled'), style: Theme.of(context).textTheme.bodySmall);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final title = _group?['title'] as String? ?? 'Group';
    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr('When your host starts a meeting, Join opens the shared video room.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FriendColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          for (final m in _meetings)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CandyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['title'] as String? ?? 'Meeting', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      trDate('EEE MMM d · h:mm a', 
                        DateTime.parse(m['scheduled_at'] as String).toLocal(),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                    ),
                    if (m['recipe'] is Map) ...[
                      const SizedBox(height: 4),
                      Text(
                        trx('Cooking: ${(m['recipe'] as Map)['title']}', 'የሚበስለው፦ ${(m['recipe'] as Map)['title']}'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.woodDeep),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: _meetingAction(m)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ClientGroupMeetingScreen extends ConsumerStatefulWidget {
  const ClientGroupMeetingScreen({super.key, required this.meetingId});
  final String meetingId;

  @override
  ConsumerState<ClientGroupMeetingScreen> createState() =>
      _ClientGroupMeetingScreenState();
}

class _ClientGroupMeetingScreenState
    extends ConsumerState<ClientGroupMeetingScreen> {
  String? _roomUrl;
  String? _jwt;
  String? _displayName;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/therapy-group-meetings/${widget.meetingId}/join',
      );
      final session =
          (res.data?['session'] as Map<String, dynamic>?) ?? const {};
      setState(() {
        _roomUrl = session['room_url'] as String?;
        _jwt = session['token'] as String?;
        _displayName = res.data?['display_name'] as String? ?? tr('Akilil');
        _starting = false;
      });
    } on DioException catch (e) {
      setState(() {
        _starting = false;
        _error = e.response?.data is Map
            ? (e.response!.data['message'] ?? "Couldn't join").toString()
            : "Couldn't join";
      });
    } catch (_) {
      setState(() {
        _starting = false;
        _error = "Couldn't join";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FriendEmptyState(
          icon: Icons.videocam_off_outlined,
          title: "Couldn't join",
          message: _error,
          ctaLabel: tr('Retry'),
          onCta: _join,
        ),
      );
    }
    if (_starting || _roomUrl == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: JitsiSessionView(
        roomUrl: _roomUrl!,
        jwt: _jwt,
        displayName: _displayName,
        mode: JitsiRoomMode.group,
        title: tr('Group session'),
        onLeave: () {
          if (mounted) Navigator.of(context).maybePop();
        },
      ),
    );
  }
}
