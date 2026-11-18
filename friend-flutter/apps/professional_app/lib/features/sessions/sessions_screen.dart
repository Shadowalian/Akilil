import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

final _sessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/appointments');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    int id,
    bool accept,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/appointments/$id/${accept ? 'accept' : 'decline'}');
      ref.invalidate(_sessionsProvider);
      if (!context.mounted) return;
      if (accept) {
        context.go('/sessions/$id/host');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Request declined.'))),
        );
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data is Map
                ? (e.response!.data['message'] ?? tr('Failed')).toString()
                : tr('Failed'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_sessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Sessions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_sessionsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, _) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: tr("Couldn't load sessions."),
          ctaLabel: tr('Try again'),
          onCta: () => ref.invalidate(_sessionsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return FriendEmptyState(
              icon: Icons.event_available_outlined,
              title: tr('No sessions yet'),
              message: tr('No sessions yet. When a client books you, it shows up here.'),
            );
          }
          final now = DateTime.now();
          bool isListening(Map a) => a['kind'] == 'listening_request' && a['status'] == 'pending';
          final listening = list.where(isListening).toList();
          // Keep confirmed / in-progress visible even if older than 2h, so
          // Join never disappears mid-call.
          final upcoming = list.where((a) {
            if (isListening(a)) return false;
            final status = a['status'] as String? ?? '';
            if (status == 'cancelled' || status == 'completed') return false;
            if (status == 'confirmed' || status == 'in_progress') return true;
            final s = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
            return s != null && s.isAfter(now.subtract(const Duration(hours: 2)));
          }).toList();
          final past = list.where((a) => a['status'] == 'completed' || a['status'] == 'cancelled').toList();
          final theme = Theme.of(context);

          return RefreshIndicator(
            color: FriendColors.primary,
            backgroundColor: FriendColors.surface,
            onRefresh: () async => ref.invalidate(_sessionsProvider),
            child: FriendContentWidth(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 8, FriendLayout.horizontal, 32),
                children: [
                  if (listening.isNotEmpty) ...[
                    FriendSectionLabel(tr('Listening requests')),
                    for (final a in listening)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CandyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(((a['client'] as Map?)?['name'] as String?) ?? tr('Client'), style: theme.textTheme.titleSmall),
                              if ((a['client_note'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(a['client_note'] as String, style: theme.textTheme.bodySmall),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FriendGlowButton(
                                      label: tr('Decline'),
                                      secondary: true,
                                      expanded: true,
                                      onPressed: () => _respond(context, ref, (a['id'] as num).toInt(), false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FriendGlowButton(
                                      label: tr('Accept & join'),
                                      expanded: true,
                                      onPressed: () => _respond(context, ref, (a['id'] as num).toInt(), true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  FriendSectionLabel(tr('Upcoming')),
                  if (upcoming.isEmpty)
                    CandyCard(child: Text(tr('Nothing scheduled.'), style: theme.textTheme.bodySmall))
                  else
                    FriendListGroup(dividerIndent: 16, children: [for (final a in upcoming) _ApptTile(appt: a)]),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: FriendLayout.sectionGap),
                    FriendSectionLabel(tr('Past')),
                    FriendListGroup(dividerIndent: 16, children: [for (final a in past.take(20)) _ApptTile(appt: a, joinable: false)]),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApptTile extends StatelessWidget {
  const _ApptTile({required this.appt, this.joinable = true});
  final Map<String, dynamic> appt;
  final bool joinable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startsAt = DateTime.parse(appt['scheduled_at'] as String);
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? tr('Guest');
    final status = appt['status'] as String? ?? 'pending';
    final kind = appt['kind'] as String? ?? 'scheduled';
    final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
    final waiting = kind == 'listening_request' && status == 'pending';
    // Mirrors the server's join window: 2 hours before until 2 hours after.
    final minsUntil = startsAt.difference(DateTime.now()).inMinutes;
    final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 50;
    final inWindow = priceCents == 0 || status == 'in_progress' || (minsUntil <= 120 && minsUntil >= -duration - 120);
    final canJoin = joinable &&
        !waiting &&
        inWindow &&
        (status == 'confirmed' || status == 'in_progress' || (status == 'pending' && priceCents == 0));
    final format = appt['care_format'] as String? ?? 'individual';
    final details = [
      trDate('EEE d MMM · h:mm a', startsAt.toLocal()),
      if (kind == 'listening_request') tr('Walk-in'),
      if (format == 'couples') tr('Couples'),
      if (format == 'family') tr('Family'),
      if (format == 'child' || format == 'teen')
        trx('For ${(appt['dependent'] as Map?)?['name'] ?? 'a child'}', 'ለ${(appt['dependent'] as Map?)?['name'] ?? 'ልጅ'}'),
      if (appt['recipe'] is Map) '${(appt['recipe'] as Map)['title']}',
    ].join(' · ');
    final (label, color) = switch (status) {
      'confirmed' when !inWindow => (tr('Upcoming'), FriendColors.success),
      'confirmed' => (tr('Confirmed'), FriendColors.success),
      'pending' => (tr('Pending'), FriendColors.warning),
      'in_progress' => (tr('In progress'), FriendColors.live),
      'cancelled' => (tr('Cancelled'), FriendColors.error),
      'completed' => (tr('Completed'), FriendColors.textSecondary),
      'no_show' => (tr('No-show'), FriendColors.error),
      _ => (status, FriendColors.textSecondary),
    };

    return InkWell(
      onTap: canJoin ? () => context.go('/sessions/${appt['id']}/host') : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(details, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (canJoin)
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => context.go('/sessions/${appt['id']}/host'),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: Text(tr('Join')),
              )
            else
              FriendStatusChip(label: label, color: color),
          ],
        ),
      ),
    );
  }
}
