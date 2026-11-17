import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

import '../auth/auth_controller.dart';
import '../shell/pro_stitch_chrome.dart';

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

/// Patient clinical dossier — Stitch layout over client + session note data.
class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.user,
    required this.sessionCount,
    this.lastSessionAt,
  });

  final Map<String, dynamic> user;
  final int sessionCount;
  final DateTime? lastSessionAt;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _busy = false;
  final Set<int> _expandedSoap = {0};

  int? get _clientId => (widget.user['id'] as num?)?.toInt();

  Future<void> _message() async {
    final id = _clientId;
    if (id == null) return;
    setState(() => _busy = true);
    var message = 'Conversation ready in Messages.';
    try {
      await ref.read(dioProvider).post('/conversations', data: {
        'participant_user_id': id,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      message = data is Map && data['message'] is String
          ? data['message'] as String
          : "Couldn't open a conversation.";
    } catch (_) {
      message = "Couldn't open a conversation.";
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addClinicalNote(Map<String, dynamic>? latestAppt) {
    final id = latestAppt?['id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete a session first to attach notes.')),
      );
      return;
    }
    context.push('/sessions/$id/notes');
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? 'Anonymous';
    final clientId = _clientId;
    final pro = ref.watch(currentUserProvider);
    final headerInset = MediaQuery.paddingOf(context).top + 56;

    if (clientId == null) {
      return const Scaffold(body: Center(child: Text('Invalid client.')));
    }

    final dossier = ref.watch(_clientDossierProvider(clientId));

    return ColoredBox(
      color: FriendColors.background,
      child: Stack(
        children: [
          dossier.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                "Couldn't load dossier.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            data: (data) {
              final appts =
                  (data['appointments'] as List).cast<Map<String, dynamic>>();
              final notesMap = data['notes'] as Map<int, List<Map<String, dynamic>>>;
              final latestNote = _latestNote(appts, notesMap);
              final intake = appts.isNotEmpty
                  ? appts.last['client_note'] as String?
                  : null;
              final last = widget.lastSessionAt ??
                  (appts.isNotEmpty
                      ? DateTime.tryParse(appts.first['scheduled_at'] as String? ?? '')
                      : null);

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  FriendLayout.horizontal,
                  headerInset + 8,
                  FriendLayout.horizontal,
                  160,
                ),
                children: [
                  _ProfileRibbon(
                    name: name,
                    sessionCount: widget.sessionCount,
                    lastSessionAt: last,
                    intakeFocus: intake,
                  ),
                  const SizedBox(height: 16),
                  _DiagnosticCard(
                    presentation: intake?.isNotEmpty == true
                        ? intake!
                        : 'Active care — intake narrative pending.',
                    modality: 'Cognitive Behavioral Therapy & clinical sync',
                  ),
                  const SizedBox(height: 16),
                  _PsychometricSection(sessionCount: widget.sessionCount),
                  const SizedBox(height: 16),
                  _SoapHistorySection(
                    appointments: appts.take(6).toList(),
                    notesMap: notesMap,
                    expanded: _expandedSoap,
                    onToggle: (index) {
                      setState(() {
                        if (_expandedSoap.contains(index)) {
                          _expandedSoap.remove(index);
                        } else {
                          _expandedSoap.add(index);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _WorksheetsSection(actionItems: latestNote?['action_items']),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _message,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(_busy ? 'Opening…' : 'Message client'),
                  ),
                ],
              );
            },
          ),
          ProStitchDossierHeader(
            onBack: () => Navigator.of(context).maybePop(),
            avatarInitial: pro?.name,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: dossier.maybeWhen(
              data: (data) {
                final appts =
                    (data['appointments'] as List).cast<Map<String, dynamic>>();
                final latest = appts.isNotEmpty ? appts.first : null;
                return _DossierActionBar(
                  onAddNote: () => _addClinicalNote(latest),
                  onCarePlan: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Care plan editor — coming soon.')),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _latestNote(
    List<Map<String, dynamic>> appts,
    Map<int, List<Map<String, dynamic>>> notesMap,
  ) {
    for (final a in appts) {
      final id = (a['id'] as num?)?.toInt();
      if (id == null) continue;
      final notes = notesMap[id];
      if (notes != null && notes.isNotEmpty) return notes.first;
    }
    return null;
  }
}

class _ProfileRibbon extends StatelessWidget {
  const _ProfileRibbon({
    required this.name,
    required this.sessionCount,
    this.lastSessionAt,
    this.intakeFocus,
  });

  final String name;
  final int sessionCount;
  final DateTime? lastSessionAt;
  final String? intakeFocus;

  @override
  Widget build(BuildContext context) {
    final memberSince = lastSessionAt != null
        ? DateFormat('MMM yyyy').format(lastSessionAt!)
        : 'Active member';
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FriendAvatar(
                    size: 56,
                    initials: name.isNotEmpty ? name[0] : '?',
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendColors.secondaryFixed,
                        border: Border.all(color: FriendColors.surfaceLowest, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FriendColors.recessed,
                            borderRadius: BorderRadius.circular(FriendRadii.pill),
                          ),
                          child: Text(
                            'ID #${name.hashCode.abs().toString().substring(0, 3)}',
                            style: GoogleFonts.inter(fontSize: 10, color: FriendColors.accent),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$sessionCount sessions • Hybrid care',
                      style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary),
                    ),
                    Text(
                      'Client since $memberSince',
                      style: GoogleFonts.inter(fontSize: 10, color: FriendColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FriendColors.secondaryFixed.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available, size: 14, color: FriendColors.accentDeep),
                        const SizedBox(width: 4),
                        Text(
                          '$sessionCount Sessions',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FriendColors.accentDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const ProStitchMicroLabel('Bi-weekly cadence'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FriendColors.recessed.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BadgeRow(
                    icon: Icons.psychology_outlined,
                    label: 'Primary axis',
                    value: intakeFocus?.isNotEmpty == true
                        ? (intakeFocus!.length > 28
                            ? '${intakeFocus!.substring(0, 28)}…'
                            : intakeFocus!)
                        : 'General wellness',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _BadgeRow(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Engagement',
                    value: 'Active in care',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: FriendColors.surfaceLowest,
            shape: BoxShape.circle,
            boxShadow: FriendElevation.card,
          ),
          child: Icon(icon, size: 16, color: FriendColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProStitchMicroLabel(label),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.presentation,
    required this.modality,
  });

  final String presentation;
  final String modality;

  @override
  Widget build(BuildContext context) {
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 18, color: FriendColors.primary),
              const SizedBox(width: 6),
              const ProStitchMicroLabel('Clinical diagnostic overview'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FriendColors.primaryLight,
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                ),
                child: Text(
                  'Active Care Protocol',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ProStitchMicroLabel('Primary diagnostic presentation'),
          Text(
            presentation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FriendColors.recessed,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRESCRIBED THERAPEUTIC MODALITY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: FriendColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high, size: 18, color: FriendColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        modality,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PsychometricSection extends StatelessWidget {
  const _PsychometricSection({required this.sessionCount});

  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProStitchMicroLabel('Longitudinal trajectory'),
                    Text(
                      'Psychometric indices',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FriendColors.secondaryFixed.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_down, size: 14, color: FriendColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '$sessionCount sessions logged',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: FriendColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _IndexCard(title: 'PHQ-9', tag: 'Depression', score: '—')),
              const SizedBox(width: 12),
              Expanded(child: _IndexCard(title: 'GAD-7', tag: 'Anxiety', score: '—')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Structured assessments sync when your clinic enables scoring.',
            style: GoogleFonts.inter(fontSize: 12, color: FriendColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({
    required this.title,
    required this.tag,
    required this.score,
  });

  final String title;
  final String tag;
  final String score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FriendColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: GoogleFonts.inter(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoapHistorySection extends StatelessWidget {
  const _SoapHistorySection({
    required this.appointments,
    required this.notesMap,
    required this.expanded,
    required this.onToggle,
  });

  final List<Map<String, dynamic>> appointments;
  final Map<int, List<Map<String, dynamic>>> notesMap;
  final Set<int> expanded;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return ProStitchCard(
        child: Text(
          'No session history yet.',
          style: GoogleFonts.inter(color: FriendColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_edu, size: 18, color: FriendColors.primary),
            const SizedBox(width: 6),
            Text(
              'SOAP Session History',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              'Showing ${appointments.length.clamp(0, 2)} of ${appointments.length}',
              style: GoogleFonts.inter(fontSize: 10, color: FriendColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < appointments.length && i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SoapCard(
              index: i,
              appointment: appointments[i],
              notes: notesMap[(appointments[i]['id'] as num?)?.toInt()] ?? const [],
              expanded: expanded.contains(i),
              onToggle: () => onToggle(i),
            ),
          ),
      ],
    );
  }
}

class _SoapCard extends StatelessWidget {
  const _SoapCard({
    required this.index,
    required this.appointment,
    required this.notes,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final Map<String, dynamic> appointment;
  final List<Map<String, dynamic>> notes;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final when = DateTime.tryParse(appointment['scheduled_at'] as String? ?? '');
    final note = notes.isNotEmpty ? notes.first : null;
    final subjective = note?['notes'] as String? ?? appointment['client_note'] as String?;
    final plan = _formatActionItems(note?['action_items']);

    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Session #${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FriendColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(FriendRadii.pill),
                          ),
                          child: Text(
                            appointment['status'] as String? ?? 'sync',
                            style: GoogleFonts.inter(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    if (when != null)
                      Text(
                        DateFormat('MMM d, yyyy • 50 mins').format(when),
                        style: GoogleFonts.inter(fontSize: 10, color: FriendColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (index > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FriendColors.secondaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(FriendRadii.small),
                  ),
                  child: Text(
                    'Archived',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (expanded && subjective?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _SoapBlock(letter: 'S', label: 'Subjective', text: subjective!, color: FriendColors.primary),
            if (plan != null)
              _SoapBlock(letter: 'P', label: 'Plan', text: plan, color: FriendColors.primaryContainer),
          ] else if (!expanded && subjective?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              subjective!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary),
            ),
          ],
          if (subjective?.isNotEmpty == true)
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Collapse Detailed SOAP' : 'Expand Detailed SOAP'),
            ),
        ],
      ),
    );
  }

  String? _formatActionItems(dynamic raw) {
    if (raw is List && raw.isNotEmpty) return raw.join(', ');
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }
}

class _SoapBlock extends StatelessWidget {
  const _SoapBlock({
    required this.letter,
    required this.label,
    required this.text,
    required this.color,
  });

  final String letter;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  letter,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FriendColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _WorksheetsSection extends StatelessWidget {
  const _WorksheetsSection({this.actionItems});

  final dynamic actionItems;

  @override
  Widget build(BuildContext context) {
    final items = actionItems is List
        ? (actionItems as List).cast<String>()
        : actionItems is String
            ? [actionItems as String]
            : const <String>[];

    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, size: 18, color: FriendColors.primary),
              const SizedBox(width: 6),
              Text(
                'Assigned Worksheets & Somatics',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${items.isEmpty ? 0 : items.length} Active',
                style: GoogleFonts.inter(fontSize: 10, color: FriendColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Action items from saved session notes appear here.',
              style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FriendColors.recessed,
                    borderRadius: BorderRadius.circular(FriendRadii.card),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FriendColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(FriendRadii.small),
                        ),
                        child: const Icon(Icons.description_outlined, color: FriendColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FriendColors.secondaryFixed.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(FriendRadii.pill),
                        ),
                        child: Text(
                          'Assigned',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
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

class _DossierActionBar extends StatelessWidget {
  const _DossierActionBar({
    required this.onAddNote,
    required this.onCarePlan,
  });

  final VoidCallback onAddNote;
  final VoidCallback onCarePlan;

  @override
  Widget build(BuildContext context) {
    return ProStitchGlassBar(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Clinical Note'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCarePlan,
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Update Care Plan'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: FriendColors.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: FriendColors.accent),
                const SizedBox(width: 6),
                Text(
                  'VISIBLE ONLY TO YOU',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: FriendColors.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
