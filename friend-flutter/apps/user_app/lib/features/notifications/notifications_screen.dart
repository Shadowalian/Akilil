import 'package:friend_user/l10n/tr.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/notifications', queryParameters: {'per_page': 50});
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/// One notification turned into words, an icon and where tapping it goes.
class _Presented {
  const _Presented(this.icon, this.color, this.title, this.body, this.route, this.group);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? route;
  final String group; // Sessions | Messages | Account
}

_Presented _present(Map<String, dynamic> n) {
  final data = (n['data'] is Map) ? Map<String, dynamic>.from(n['data'] as Map) : const <String, dynamic>{};
  final type = (data['type'] ?? n['type'] ?? '').toString();
  final when = DateTime.tryParse('${data['scheduled_at']}')?.toLocal();
  final at = when == null ? '' : trDate('EEE MMM d, h:mm a', when);
  final appt = data['appointment_id'];
  final pro = data['professional'] ?? 'your professional';

  return switch (type) {
    'booking_confirmed' => _Presented(Icons.event_available_rounded, FriendColors.primary, tr('Session booked'),
        trx('With $pro${at.isEmpty ? '' : ' · $at'}', 'ከ$pro ጋር${at.isEmpty ? '' : ' · $at'}'), '/appointments', 'Sessions'),
    'reminder_24h' => _Presented(Icons.alarm_rounded, FriendColors.accent, tr('Your session is tomorrow'),
        at.isEmpty ? tr('Check your sessions for the time.') : at, '/appointments', 'Sessions'),
    'reminder_1h' => _Presented(Icons.videocam_rounded, FriendColors.coral, tr('Your session starts in an hour'),
        tr('Open the waiting room a few minutes early.'), appt == null ? '/appointments' : '/appointments/$appt/room', 'Sessions'),
    'new_message' => _Presented(Icons.forum_rounded, FriendColors.wood, tr('New message'),
        (data['preview'] ?? tr('You have a new message.')).toString(),
        data['conversation_id'] == null ? '/messages' : '/messages/${data['conversation_id']}', 'Messages'),
    _ => _Presented(Icons.notifications_rounded, FriendColors.primary, tr('Update'),
        (data['message'] ?? data['body'] ?? tr('Something changed on your account.')).toString(), null, 'Account'),
  };
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Internal values stay English; only the chip labels are translated.
  String _filter = 'All';

  Future<void> _markAllRead() async {
    try {
      await ref.read(dioProvider).post('/notifications/read-all');
    } catch (_) {}
    ref.invalidate(_notificationsProvider);
  }

  Future<void> _open(Map<String, dynamic> n, _Presented p) async {
    if (n['read_at'] == null) {
      ref.read(dioProvider).post('/notifications/${n['id']}/read').ignore();
    }
    if (p.route != null) {
      context.push(p.route!);
    }
    ref.invalidate(_notificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_notificationsProvider);
    final theme = Theme.of(context);
    return FriendPageScaffold(
      eyebrow: tr('Activity'),
      title: tr('Notifications'),
      trailing: IconButton(
        onPressed: _markAllRead,
        tooltip: tr('Mark all read'),
        icon: const Icon(Icons.done_all_rounded),
      ),
      onRefresh: () async => ref.invalidate(_notificationsProvider),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load notifications",
          ctaLabel: tr('Try again'),
          onCta: () => ref.invalidate(_notificationsProvider),
        ),
        data: (all) {
          final items = [
            for (final n in all) (n, _present(n)),
          ].where((e) => _filter == 'All' || e.$2.group == _filter).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const ['All', 'Sessions', 'Messages', 'Account'])
                    ChoiceChip(
                      label: Text(tr(f)),
                      showCheckmark: false,
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                FriendEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: tr('You are all caught up'),
                  message: tr('Bookings, reminders and messages will show up here.'),
                ),
              for (final (n, p) in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CandyCard(
                    onTap: () => _open(n, p),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(p.icon, color: p.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(p.body,
                                  style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(
                                _ago(DateTime.tryParse('${n['created_at']}')),
                                style: theme.textTheme.labelSmall?.copyWith(color: FriendColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (n['read_at'] == null)
                          Container(
                            margin: const EdgeInsets.only(top: 6, left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: FriendColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _ago(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return tr('Just now');
  if (d.inMinutes < 60) return trx('${d.inMinutes} min ago', 'ከ${d.inMinutes} ደቂቃ በፊት');
  if (d.inHours < 24) return trx('${d.inHours} h ago', 'ከ${d.inHours} ሰዓት በፊት');
  if (d.inDays < 7) return trx('${d.inDays} d ago', 'ከ${d.inDays} ቀን በፊት');
  return trDate('MMM d', t.toLocal());
}
