import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

import 'client_detail_screen.dart';

/// Clients list — guests the pro has hosted at least once. Pulls
/// from /me/professional-profile's sessions and groups by guest user.
/// v1: flat list with last-session date and total session count.
final _clientsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/clients');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load clients.")),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: FriendColors.textMuted),
                    SizedBox(height: 8),
                    Text('No clients yet. Complete a session to start your list.'),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = list[i];
              final user = c['user'] as Map<String, dynamic>? ?? const {};
              final last = DateTime.tryParse(c['last_session_at'] as String? ?? '');
              return ListTile(
                leading: CircleAvatar(
                  child: Text(personInitial(user['name'] as String?)),
                ),
                title: Text(user['name'] as String? ?? 'Anonymous'),
                subtitle: Text(
                  '${c['session_count'] ?? 0} sessions'
                  '${last != null ? " • last ${DateFormat('MMM d').format(last)}" : ""}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ClientDetailScreen(
                      user: user,
                      sessionCount: (c['session_count'] as num?)?.toInt() ?? 0,
                      lastSessionAt: last,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}