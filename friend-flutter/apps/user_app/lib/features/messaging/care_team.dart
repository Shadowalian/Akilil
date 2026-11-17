import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The professionals this person has booked, most recent first, from their
/// real appointments. Used by Messages, Settings and Switch professional.
final careTeamProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/appointments', queryParameters: {'per_page': 50});
  final appts = ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  final seen = <int>{};
  final team = <Map<String, dynamic>>[];
  for (final a in appts) {
    final pro = a['professional'];
    final id = (a['professional_user_id'] as num?)?.toInt();
    if (pro is! Map || id == null || !seen.add(id)) continue;
    team.add({
      'user_id': id,
      'profile_id': a['professional_profile_id'],
      'name': pro['name'],
      'last_at': a['scheduled_at'],
    });
  }
  return team;
});
