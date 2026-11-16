import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../studio/studio_screens.dart';

final _proGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/therapy-groups');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New therapy group'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Group title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true || titleCtrl.text.trim().length < 2) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/therapy-groups',
        data: {'title': titleCtrl.text.trim(), 'is_open': true},
      );
      final id = res.data?['group']?['id'];
      ref.invalidate(_proGroupsProvider);
      if (!context.mounted) return;
      if (id != null) context.go('/groups/$id');
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message'] ?? 'Create failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_proGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGroup(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Couldn't load groups.")),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Create a group for multi-person sessions. Clients can join when it is open.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_proGroupsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final g = list[i];
                final members = g['member_count'] ?? 0;
                return Card(
                  child: ListTile(
                    title: Text(g['title'] as String? ?? 'Group'),
                    subtitle: Text(
                      '${g['status']} · $members members'
                      '${g['is_open'] == true ? ' · open' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/groups/${g['id']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _meetings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final g = await dio.get<Map<String, dynamic>>(
        '/therapy-groups/${widget.groupId}',
      );
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
      setState(() {
        _loading = false;
        _error = "Couldn't load group.";
      });
    }
  }

  Future<void> _scheduleMeeting() async {
    // A cooking class needs a recipe and a day's notice so people can shop.
    final isCooking = _group?['is_cooking_class'] == true;
    int? recipeId;
    var when = DateTime.now().add(const Duration(minutes: 5));
    if (isCooking) {
      recipeId = await pickPublishedRecipe(context, ref);
      if (recipeId == null || !mounted) return;
      final picked = await pickDateTime(context, earliest: DateTime.now().add(const Duration(hours: 25)));
      if (picked == null || !mounted) return;
      when = picked;
    }
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/therapy-groups/${widget.groupId}/meetings',
        data: {
          'scheduled_at': when.toUtc().toIso8601String(),
          'title': _group?['title'],
          'duration_minutes': 60,
          if (recipeId != null) 'recipe_id': recipeId,
        },
      );
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e.response?.data, 'Could not schedule'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule failed: $e')),
      );
    }
  }

  Future<void> _startMeeting(int meetingId) async {
    context.go('/groups/meetings/$meetingId/host');
  }

  Future<void> _archive() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/therapy-groups/${widget.groupId}/archive');
      ref.invalidate(_proGroupsProvider);
      if (!mounted) return;
      context.go('/groups');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archive failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Missing group')),
      );
    }
    final title = _group!['title'] as String? ?? 'Group';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archive,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _group!['description'] as String? ??
                'Open group therapy room. Schedule a meeting, then Start for members to Join.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FriendGlowButton(
            label: _group?['is_cooking_class'] == true ? 'Schedule a class' : 'Start a meeting',
            icon: Icons.event,
            expanded: true,
            onPressed: _scheduleMeeting,
          ),
          const SizedBox(height: 20),
          Text('Meetings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_meetings.isEmpty)
            const Text('No meetings yet.')
          else
            for (final m in _meetings)
              Card(
                child: ListTile(
                  title: Text(m['title'] as String? ?? 'Meeting'),
                  subtitle: Text(
                    '${DateFormat('EEE MMM d · h:mm a').format(DateTime.parse(m['scheduled_at'] as String).toLocal())} · ${m['status']}',
                  ),
                  trailing: (m['status'] == 'scheduled' || m['status'] == 'live')
                      ? FilledButton(
                          onPressed: () =>
                              _startMeeting((m['id'] as num).toInt()),
                          child: Text(m['status'] == 'live' ? 'Rejoin' : 'Start'),
                        )
                      : null,
                ),
              ),
        ],
      ),
    );
  }
}

/// Host / join a group meeting room (same Jitsi embed as 1:1).
class GroupMeetingHostScreen extends ConsumerStatefulWidget {
  const GroupMeetingHostScreen({
    super.key,
    required this.meetingId,
    this.asHost = true,
  });

  final String meetingId;
  final bool asHost;

  @override
  ConsumerState<GroupMeetingHostScreen> createState() =>
      _GroupMeetingHostScreenState();
}

class _GroupMeetingHostScreenState
    extends ConsumerState<GroupMeetingHostScreen> {
  String? _roomUrl;
  String? _jwt;
  String? _displayName;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final path = widget.asHost
          ? '/therapy-group-meetings/${widget.meetingId}/start'
          : '/therapy-group-meetings/${widget.meetingId}/join';
      final res = await dio.post<Map<String, dynamic>>(path);
      final session =
          (res.data?['session'] as Map<String, dynamic>?) ?? const {};
      setState(() {
        _roomUrl = session['room_url'] as String?;
        _jwt = session['token'] as String?;
        _displayName = res.data?['display_name'] as String? ?? 'Akilil';
        _starting = false;
      });
    } on DioException catch (e) {
      setState(() {
        _starting = false;
        _error = e.response?.data is Map
            ? (e.response!.data['message'] ?? "Couldn't open room").toString()
            : "Couldn't open room";
      });
    } catch (_) {
      setState(() {
        _starting = false;
        _error = "Couldn't open room";
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
          title: "Couldn't open video",
          message: _error,
          ctaLabel: 'Retry',
          onCta: _open,
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
        title: 'Group session',
        onLeave: () {
          if (widget.asHost) {
            // Closing the room as host ends the meeting and books earnings.
            ref.read(dioProvider).post('/therapy-group-meetings/${widget.meetingId}/end').ignore();
          }
          if (mounted) Navigator.of(context).maybePop();
        },
      ),
    );
  }
}
