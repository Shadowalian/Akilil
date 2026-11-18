import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../auth/auth_controller.dart';
import '../shell/pro_stitch_chrome.dart';

/// The client's safety plan (empty lists when they have not written one).
final _safetyPlanProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, userId) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/professional/clients/$userId/safety-plan');
  return res.data ?? const {};
});

final _clientDossierProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, clientUserId) async {
  final dio = ref.read(dioProvider);
  final apptsRes = await dio.get<Map<String, dynamic>>(
    '/professional/appointments',
    queryParameters: {'per_page': 100},
  );
  final all = ((apptsRes.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
  final mine = all.where((a) {
    final client = a['client'] as Map<String, dynamic>?;
    return (client?['id'] as num?)?.toInt() == clientUserId;
  }).toList()
    ..sort((a, b) {
      final ta = DateTime.tryParse(a['scheduled_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['scheduled_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

  final notesByAppt = <int, List<Map<String, dynamic>>>{};
  for (final a in mine.take(6)) {
    final id = (a['id'] as num?)?.toInt();
    if (id == null) continue;
    try {
      final res = await dio.get<Map<String, dynamic>>('/appointments/$id/notes');
      notesByAppt[id] =
          ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    } catch (_) {
      notesByAppt[id] = const [];
    }
  }

  return {
    'appointments': mine,
    'notes': notesByAppt,
  };
});

/// A client's record: who they are, what they shared, your session notes,
/// action items and their safety plan. Private to the professional.
class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.user, required this.sessionCount, this.lastSessionAt});

  final Map<String, dynamic> user;
  final int sessionCount;
  final DateTime? lastSessionAt;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _busy = false;
  final Set<int> _expanded = {0};

  int? get _clientId => (widget.user['id'] as num?)?.toInt();

  Future<void> _message() async {
    final id = _clientId;
    if (id == null) return;
    setState(() => _busy = true);
    var message = tr('Conversation ready in Messages.');
    try {
      await ref.read(dioProvider).post('/conversations', data: {'participant_user_id': id});
    } on DioException catch (e) {
      final data = e.response?.data;
      message = data is Map && data['message'] is String ? data['message'] as String : tr("Couldn't open a conversation.");
    } catch (_) {
      message = tr("Couldn't open a conversation.");
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Notes belong to a session that has happened; never a future booking.
  void _addNote(List<Map<String, dynamic>> appts) {
    final now = DateTime.now();
    final done = appts.where((a) {
      final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
      final status = a['status'] as String? ?? '';
      return status == 'completed' || status == 'in_progress' || (when != null && when.isBefore(now) && status != 'cancelled');
    });
    final target = done.isEmpty ? null : done.first;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Complete a session first to attach notes.'))));
      return;
    }
    context.push('/sessions/${target['id']}/notes');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.user['name'] as String? ?? tr('Anonymous');
    final clientId = _clientId;
    final pro = ref.watch(currentUserProvider);

    if (clientId == null) {
      return Scaffold(body: FriendEmptyState(icon: Icons.person_off_outlined, title: tr('Invalid client.')));
    }
    final dossier = ref.watch(_clientDossierProvider(clientId));

    return Material(
      color: FriendColors.background,
      child: Column(
        children: [
          ProStitchDossierHeader(onBack: () => Navigator.of(context).maybePop(), avatarInitial: pro?.name),
          Expanded(
            child: dossier.when(
              loading: () => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => FriendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: tr("Couldn't load this record."),
                ctaLabel: tr('Try again'),
                onCta: () => ref.invalidate(_clientDossierProvider(clientId)),
              ),
              data: (data) {
                final appts = (data['appointments'] as List).cast<Map<String, dynamic>>();
                final notesMap = data['notes'] as Map<int, List<Map<String, dynamic>>>;
                final latestNote = _latestNote(appts, notesMap);
                final intake = appts.isNotEmpty ? (appts.last['client_note'] as String?)?.trim() : null;
                final first = appts.isNotEmpty ? DateTime.tryParse(appts.last['scheduled_at'] as String? ?? '')?.toLocal() : null;
                final completed = appts.where((a) => a['status'] == 'completed').length;

                return FriendContentWidth(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 20, FriendLayout.horizontal, 32),
                    children: [
                      Row(
                        children: [
                          FriendAvatar(size: 60, initials: personInitial(name)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: theme.textTheme.headlineMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    trx('$completed completed', '$completed የተጠናቀቁ'),
                                    if (first != null) trx('since ${trDate('MMM y', first)}', 'ከ${trDate('MMM y', first)} ጀምሮ'),
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FriendSectionLabel(tr('What they shared when booking')),
                      CandyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              intake?.isNotEmpty == true ? intake! : tr('They have not left a note when booking.'),
                              style: intake?.isNotEmpty == true
                                  ? theme.textTheme.bodyMedium
                                  : theme.textTheme.bodySmall,
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                const Icon(Icons.event_note_outlined, size: 18, color: FriendColors.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_formatSummary(appts), style: theme.textTheme.bodySmall)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FriendLayout.sectionGap),
                      FriendSectionLabel(tr('Session notes')),
                      _NotesList(
                        appointments: appts.take(6).toList(),
                        notesMap: notesMap,
                        expanded: _expanded,
                        onToggle: (i) => setState(() => _expanded.contains(i) ? _expanded.remove(i) : _expanded.add(i)),
                      ),
                      const SizedBox(height: FriendLayout.sectionGap),
                      FriendSectionLabel(tr('Action items')),
                      _ActionItems(actionItems: latestNote?['action_items']),
                      const SizedBox(height: FriendLayout.sectionGap),
                      FriendSectionLabel(tr('Their safety plan')),
                      _SafetyPlanCard(plan: ref.watch(_safetyPlanProvider(clientId)).valueOrNull),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 14, color: FriendColors.textMuted),
                          const SizedBox(width: 6),
                          Text(tr('Visible only to you'), style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          dossier.maybeWhen(
            data: (data) {
              final appts = (data['appointments'] as List).cast<Map<String, dynamic>>();
              return FriendGlassBar(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FriendGlowButton(
                          label: tr('Message'),
                          icon: Icons.chat_bubble_outline_rounded,
                          secondary: true,
                          expanded: true,
                          busy: _busy,
                          onPressed: _message,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FriendGlowButton(
                          label: tr('Add note'),
                          icon: Icons.edit_note_rounded,
                          expanded: true,
                          onPressed: () => _addNote(appts),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// "Couples, Family · cooked: Doro wot · 6 booked" — from the real bookings.
  String _formatSummary(List<Map<String, dynamic>> appts) {
    final formats = {for (final a in appts) (a['care_format'] as String? ?? 'individual')};
    final recipes = {for (final a in appts) if (a['recipe'] is Map) (a['recipe'] as Map)['title']};
    return [
      formats.map((f) => switch (f) {
            'couples' => tr('Couples'),
            'family' => tr('Family'),
            'child' => tr('Children'),
            'teen' => tr('Teens'),
            _ => tr('Individual'),
          }).join(', '),
      if (recipes.isNotEmpty) trx('cooked: ${recipes.join(', ')}', 'ያበሰሉት፦ ${recipes.join('፣ ')}'),
      trx('${appts.length} booked', '${appts.length} ቀጠሮዎች'),
    ].join(' · ');
  }

  Map<String, dynamic>? _latestNote(List<Map<String, dynamic>> appts, Map<int, List<Map<String, dynamic>>> notesMap) {
    for (final a in appts) {
      final notes = notesMap[(a['id'] as num?)?.toInt()];
      if (notes != null && notes.isNotEmpty) return notes.first;
    }
    return null;
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.appointments, required this.notesMap, required this.expanded, required this.onToggle});

  final List<Map<String, dynamic>> appointments;
  final Map<int, List<Map<String, dynamic>>> notesMap;
  final Set<int> expanded;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (appointments.isEmpty) {
      return CandyCard(child: Text(tr('No session history yet.'), style: theme.textTheme.bodySmall));
    }
    return FriendListGroup(
      dividerIndent: 16,
      children: [
        for (var i = 0; i < appointments.length; i++)
          _NoteRow(
            appointment: appointments[i],
            notes: notesMap[(appointments[i]['id'] as num?)?.toInt()] ?? const [],
            expanded: expanded.contains(i),
            onToggle: () => onToggle(i),
          ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.appointment, required this.notes, required this.expanded, required this.onToggle});

  final Map<String, dynamic> appointment;
  final List<Map<String, dynamic>> notes;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateTime.tryParse(appointment['scheduled_at'] as String? ?? '')?.toLocal();
    final note = notes.isNotEmpty ? notes.first : null;
    final text = (note?['notes'] as String?)?.trim();
    final plan = _actionText(note?['action_items']);
    final hasNote = text != null && text.isNotEmpty;
    final status = appointment['status'] as String?;
    final duration = appointment['duration_minutes'] ?? 50;

    return InkWell(
      onTap: hasNote ? onToggle : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    when == null ? tr('Session') : '${trDate('EEE d MMM y', when)} · ${trx('$duration min', '$duration ደቂቃ')}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                FriendStatusChip(label: _statusLabel(status), color: _statusColor(status)),
              ],
            ),
            const SizedBox(height: 6),
            if (!hasNote)
              Text(tr('No note written for this session.'), style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textMuted))
            else ...[
              Text(
                text,
                maxLines: expanded ? null : 2,
                overflow: expanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary),
              ),
              if (expanded && plan != null) ...[
                const SizedBox(height: 10),
                Text(tr('Plan'), style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(plan, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 6),
              Text(
                expanded ? tr('Show less') : tr('Show full note'),
                style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _actionText(dynamic raw) {
    if (raw is List && raw.isNotEmpty) return raw.join(', ');
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }
}

class _ActionItems extends StatelessWidget {
  const _ActionItems({this.actionItems});

  final dynamic actionItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = actionItems is List
        ? (actionItems as List).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList()
        : actionItems is String && (actionItems as String).trim().isNotEmpty
            ? [actionItems as String]
            : const <String>[];
    if (items.isEmpty) {
      return CandyCard(child: Text(tr('Action items from saved session notes appear here.'), style: theme.textTheme.bodySmall));
    }
    return FriendListGroup(
      dividerIndent: 48,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.radio_button_unchecked_rounded, size: 18, color: FriendColors.textMuted),
                const SizedBox(width: 14),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

String _statusLabel(String? status) => switch (status) {
      'completed' => tr('Completed'),
      'confirmed' => tr('Upcoming'),
      'in_progress' => tr('In progress'),
      'cancelled' => tr('Cancelled'),
      'no_show' => tr('No-show'),
      _ => tr('Booked'),
    };

Color _statusColor(String? status) => switch (status) {
      'completed' => FriendColors.textSecondary,
      'confirmed' => FriendColors.success,
      'in_progress' => FriendColors.live,
      'cancelled' || 'no_show' => FriendColors.error,
      _ => FriendColors.warning,
    };

/// Read-only view of the client's own safety plan.
class _SafetyPlanCard extends StatelessWidget {
  const _SafetyPlanCard({required this.plan});
  final Map<String, dynamic>? plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = plan;
    List<String> list(String key) => ((p?[key] as List?) ?? const []).map((e) => '$e').toList();
    final people = ((p?['people'] as List?) ?? const [])
        .map((e) => '${(e as Map)['name']}${(e['phone'] ?? '').toString().isEmpty ? '' : ' · ${e['phone']}'}')
        .toList();
    final empty = p == null || [list('warning_signs'), list('coping'), people, list('environment')].every((l) => l.isEmpty);

    if (empty) {
      return CandyCard(
        child: Text(
          tr('They have not written one yet. If it fits your work together, you could build it with them in a session.'),
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    Widget part(String title, List<String> items) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
                const SizedBox(height: 4),
                for (final i in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('•  $i', style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
          );

    return CandyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          part(tr('Warning signs'), list('warning_signs')),
          part(tr('Things that help'), list('coping')),
          part(tr('People they can call'), people),
          part(tr('Making things safer'), list('environment')),
        ],
      ),
    );
  }
}
