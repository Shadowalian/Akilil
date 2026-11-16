import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
          const SnackBar(content: Text('Request declined.')),
        );
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data is Map
                ? (e.response!.data['message'] ?? 'Failed').toString()
                : 'Failed',
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
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_sessionsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load sessions.")),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No sessions yet. When a client books you, it shows up here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final now = DateTime.now();
          final listening = list
              .where((a) =>
                  (a['kind'] as String? ?? '') == 'listening_request' &&
                  (a['status'] as String? ?? '') == 'pending')
              .toList();
          // Keep confirmed / in-progress (esp. free listening) visible even if
          // scheduled_at is older than 2h — otherwise Join disappears mid-call.
          final upcoming = list.where((a) {
            if ((a['kind'] as String? ?? '') == 'listening_request' &&
                (a['status'] as String? ?? '') == 'pending') {
              return false;
            }
            final status = a['status'] as String? ?? '';
            if (status == 'cancelled' || status == 'completed') return false;
            if (status == 'confirmed' || status == 'in_progress') return true;
            final s = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
            return s != null &&
                s.isAfter(now.subtract(const Duration(hours: 2)));
          }).toList();
          final past = list.where((a) {
            final status = a['status'] as String? ?? '';
            return status == 'completed' || status == 'cancelled';
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_sessionsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (listening.isNotEmpty) ...[
                  Text('Listening requests',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final a in listening)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ((a['client'] as Map?)?['name'] as String?) ??
                                  'Client',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((a['client_note'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 4),
                              Text(a['client_note'] as String),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: () => _respond(
                                    context,
                                    ref,
                                    (a['id'] as num).toInt(),
                                    true,
                                  ),
                                  child: const Text('Accept & join'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _respond(
                                    context,
                                    ref,
                                    (a['id'] as num).toInt(),
                                    false,
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                if (upcoming.isNotEmpty) ...[
                  Text('Ready to join',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final a in upcoming) _ApptTile(appt: a),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Past', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final a in past.take(20)) _ApptTile(appt: a, joinable: false),
                ],
              ],
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
    final startsAt = DateTime.parse(appt['scheduled_at'] as String);
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? 'Guest';
    final status = appt['status'] as String? ?? 'pending';
    final kind = appt['kind'] as String? ?? 'scheduled';
    final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
    final waiting =
        kind == 'listening_request' && status == 'pending';
    final canJoin = joinable &&
        !waiting &&
        (status == 'confirmed' ||
            status == 'in_progress' ||
            (status == 'pending' && priceCents == 0));

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          '${DateFormat('EEE, MMM d • h:mm a').format(startsAt.toLocal())}'
          '${kind == 'listening_request' ? ' · listening' : ''}'
          ' · $status',
        ),
        trailing: canJoin
            ? FilledButton.icon(
                onPressed: () => context.go('/sessions/${appt['id']}/host'),
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join'),
              )
            : Text(
                status,
                style: TextStyle(color: _statusColor(status), fontSize: 12),
              ),
        onTap: canJoin
            ? () => context.go('/sessions/${appt['id']}/host')
            : null,
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'confirmed' => FriendColors.primary,
        'pending' => FriendColors.accent,
        'cancelled' => FriendColors.error,
        'completed' => FriendColors.textSecondary,
        _ => FriendColors.textSecondary,
      };
}
