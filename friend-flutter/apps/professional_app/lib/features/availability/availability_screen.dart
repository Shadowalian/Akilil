import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

import '../studio/studio_screens.dart';

/// Availability management. Two halves: weekly rules (the recurring
/// "I'm free Mondays 9–5") and one-off blocks (vacations, sick days).
/// Both are list views with FABs to add new entries.
final _rulesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/availability');
  return ((res.data?['rules'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

final _blocksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professional/availability/blocks');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/// The professional's own session length, so slots match bookings.
Future<int> _sessionMinutes(WidgetRef ref) async {
  try {
    final profile = await ref.read(myProfileProvider.future);
    final data = (profile['data'] as Map?) ?? profile;
    return (data['session_duration_minutes'] as num?)?.toInt() ?? 50;
  } catch (_) {
    return 50;
  }
}

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(_rulesProvider);
    final blocks = ref.watch(_blocksProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Schedule')),
          bottom: TabBar(tabs: [
            Tab(text: tr('Weekly hours')),
            Tab(text: tr('Time off')),
          ]),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TabBarView(children: [
                _RulesList(
                  provider: rules,
                  onChanged: () => ref.invalidate(_rulesProvider),
                ),
                _BlocksList(
                  provider: blocks,
                  onChanged: () => ref.invalidate(_blocksProvider),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesList extends ConsumerWidget {
  const _RulesList({
    required this.provider,
    required this.onChanged,
  });
  final AsyncValue<List<Map<String, dynamic>>> provider;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: provider.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FriendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: tr("Couldn't load hours."),
          ctaLabel: tr('Try again'),
          onCta: onChanged,
        ),
        data: (list) => list.isEmpty
            ? FriendEmptyState(
                icon: Icons.calendar_month_outlined,
                title: tr('No weekly hours yet'),
                message: tr('Clients can only book the hours you open here.'),
                ctaLabel: tr('Use typical hours (Mon–Sat, 9:00–18:00)'),
                onCta: () => _setTypicalHours(context, ref, onChanged),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 16, FriendLayout.horizontal, 100),
                children: [
                  FriendListGroup(
                    dividerIndent: 16,
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                child: Text(_weekdayName(r['weekday'] as int?), style: Theme.of(context).textTheme.titleSmall),
                              ),
                              Expanded(
                                child: Text(
                                  '${_hhmm(r['start_time'])} – ${_hhmm(r['end_time'])}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFeatures: friendTabular),
                                ),
                              ),
                              IconButton(
                                tooltip: tr('Remove'),
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                onPressed: () async {
                                  await ref.read(dioProvider).delete('/professional/availability/rules/${r['id']}');
                                  onChanged();
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRule(context, ref, onSaved: onChanged),
        icon: const Icon(Icons.add),
        label: Text(tr('Add hours')),
      ),
    );
  }

  static String _hhmm(Object? t) {
    final v = '$t';
    return v.length >= 5 ? v.substring(0, 5) : v;
  }

  /// Opens Monday to Saturday, 9:00–18:00, using the professional's own
  /// session length so back-to-back bookings never overlap.
  Future<void> _setTypicalHours(BuildContext context, WidgetRef ref, VoidCallback onSaved) async {
    final dio = ref.read(dioProvider);
    final minutes = await _sessionMinutes(ref);
    try {
      for (var day = 1; day <= 6; day++) {
        await dio.post('/professional/availability/rules', data: {
          'weekday': day,
          'start_time': '09:00',
          'end_time': '18:00',
          'slot_duration_minutes': minutes,
          'buffer_minutes': 10,
          'timezone': 'Africa/Addis_Ababa',
          'is_active': true,
        });
      }
      onSaved();
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_saveError(e))));
    }
  }

  String _weekdayName(int? w) =>
      [tr('Mon'), tr('Tue'), tr('Wed'), tr('Thu'), tr('Fri'), tr('Sat'), tr('Sun')][(w ?? 1).clamp(1, 7) - 1];

  void _showAddRule(BuildContext context, WidgetRef ref, {required VoidCallback onSaved}) {
    int weekday = 1;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Add weekly hours'), style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: InputDecoration(labelText: tr('Day')),
                  items: [
                    for (var i = 1; i <= 7; i++)
                      DropdownMenuItem(value: i, child: Text(_weekdayName(i))),
                  ],
                  onChanged: (v) => setState(() => weekday = v ?? 1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: start);
                          if (t != null) setState(() => start = t);
                        },
                        child: Text(trx('Start ${_fmt(start)}', 'መጀመሪያ ${_fmt(start)}')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: end);
                          if (t != null) setState(() => end = t);
                        },
                        child: Text(trx('End ${_fmt(end)}', 'መጨረሻ ${_fmt(end)}')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final dio = ref.read(dioProvider);
                    final minutes = await _sessionMinutes(ref);
                    try {
                      await dio.post('/professional/availability/rules', data: {
                        'weekday': weekday,
                        'start_time': _fmt(start),
                        'end_time': _fmt(end),
                        'slot_duration_minutes': minutes,
                        'buffer_minutes': 10,
                        'timezone': 'Africa/Addis_Ababa',
                        'is_active': true,
                      });
                      onSaved();
                      if (ctx.mounted) Navigator.pop(sheetCtx);
                    } on DioException catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(_saveError(e))),
                        );
                      }
                    }
                  },
                  child: Text(tr('Save')),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _saveError(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    final message = data['message'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError) {
    return tr('Network error — check connection and try again.');
  }
  return "Couldn't save. Try again.";
}

class _BlocksList extends ConsumerWidget {
  const _BlocksList({required this.provider, required this.onChanged});
  final AsyncValue<List<Map<String, dynamic>>> provider;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: provider.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load blocks.")),
        data: (list) => list.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(tr('No time off scheduled.')),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final b = list[i];
                  final from = DateTime.parse(
                    (b['start_at'] ?? b['starts_at']) as String,
                  );
                  final to = DateTime.parse(
                    (b['end_at'] ?? b['ends_at']) as String,
                  );
                  return Card(
                    child: ListTile(
                      title: Text(b['reason'] as String? ?? tr('Blocked')),
                      subtitle: Text(
                        '${trDate('MMM d', from)} → ${trDate('MMM d', to)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final dio = ref.read(dioProvider);
                          await dio.delete('/professional/availability/blocks/${b['id']}');
                          onChanged();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBlock(context, ref, onSaved: onChanged),
        icon: const Icon(Icons.add),
        label: Text(tr('Add time off')),
      ),
    );
  }

  void _showAddBlock(BuildContext context, WidgetRef ref, {required VoidCallback onSaved}) {
    DateTime from = DateTime.now();
    DateTime to = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Block time off'), style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Reason'),
                    hintText: tr('Vacation, sick day, focus week...'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: from,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => from = d);
                        },
                        child: Text('From: ${trDate('MMM d', from)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: to,
                            firstDate: from,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => to = d);
                        },
                        child: Text('To: ${trDate('MMM d', to)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final dio = ref.read(dioProvider);
                    try {
                      await dio.post('/professional/availability/blocks', data: {
                        'reason': reasonCtrl.text.trim().isEmpty
                            ? null
                            : reasonCtrl.text.trim(),
                        'start_at': DateTime(from.year, from.month, from.day)
                            .toUtc()
                            .toIso8601String(),
                        'end_at': DateTime(to.year, to.month, to.day, 23, 59)
                            .toUtc()
                            .toIso8601String(),
                      });
                      onSaved();
                      if (ctx.mounted) Navigator.pop(sheetCtx);
                    } on DioException catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(_saveError(e))),
                        );
                      }
                    }
                  },
                  child: Text(tr('Save')),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}