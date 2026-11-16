import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

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

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  Future<void> _setEveryDayEveryTime(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    try {
      for (var day = 1; day <= 7; day++) {
        await dio.post('/professional/availability/rules', data: {
          'weekday': day,
          'start_time': '00:00',
          'end_time': '23:59',
          'slot_duration_minutes': 45,
          'buffer_minutes': 0,
          'timezone': 'Africa/Addis_Ababa',
          'is_active': true,
        });
      }
      ref.invalidate(_rulesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open every day, all day.')),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_saveError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(_rulesProvider);
    final blocks = ref.watch(_blocksProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Weekly hours'),
            Tab(text: 'Time off'),
          ]),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                onPressed: () => _setEveryDayEveryTime(context, ref),
                icon: const Icon(Icons.all_inclusive),
                label: const Text('Every day, every time'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Opens Mon–Sun, 00:00–23:59 for bookings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
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
        error: (e, _) => Center(child: Text("Couldn't load hours.")),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No weekly hours yet. Tap “Every day, every time” above, or Add hours.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(_weekdayName(r['weekday'] as int?)),
                      subtitle: Text('${r['start_time']} – ${r['end_time']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final dio = ref.read(dioProvider);
                          await dio.delete(
                            '/professional/availability/rules/${r['id']}',
                          );
                          onChanged();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRule(context, ref, onSaved: onChanged),
        icon: const Icon(Icons.add),
        label: const Text('Add hours'),
      ),
    );
  }

  String _weekdayName(int? w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(w ?? 1).clamp(1, 7) - 1];

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
                Text('Add weekly hours', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: 'Day'),
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
                        child: Text('Start: ${_fmt(start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: end);
                          if (t != null) setState(() => end = t);
                        },
                        child: Text('End: ${_fmt(end)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final dio = ref.read(dioProvider);
                    try {
                      await dio.post('/professional/availability/rules', data: {
                        'weekday': weekday,
                        'start_time': _fmt(start),
                        'end_time': _fmt(end),
                        'slot_duration_minutes': 45,
                        'buffer_minutes': 0,
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
                  child: const Text('Save'),
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
    return 'Network error — check connection and try again.';
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
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No time off scheduled.'),
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
                      title: Text(b['reason'] as String? ?? 'Blocked'),
                      subtitle: Text(
                        '${DateFormat('MMM d').format(from)} → ${DateFormat('MMM d').format(to)}',
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
        label: const Text('Add time off'),
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
                Text('Block time off', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Vacation, sick day, focus week...',
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
                        child: Text('From: ${DateFormat('MMM d').format(from)}'),
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
                        child: Text('To: ${DateFormat('MMM d').format(to)}'),
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
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}