import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../brand/freud_art.dart';

/// Journal editor — create or edit an entry. Sends the body markdown
/// to the server. The 1–7 mood picker is part of the spec — feeds
/// into the analytics chart on the next screen.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key, this.entryId});
  final String? entryId;

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _mood;
  bool _busy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/journal-entries/${widget.entryId}');
      final data = res.data?['data'] as Map<String, dynamic>? ?? res.data ?? const {};
      setState(() {
        _title.text = data['title'] as String? ?? '';
        _body.text = data['content'] as String? ?? '';
        _mood = (data['mood_score'] as num?)?.toInt();
      });
    } catch (_) {
      // Will show empty editor if load fails; the user can re-type.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Write something first.'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'title': _title.text.trim().isEmpty ? null : _title.text.trim(),
        'content': _body.text,
        'mood_score': _mood,
      };
      if (widget.entryId == null) {
        await dio.post('/journal-entries', data: payload);
      } else {
        await dio.put('/journal-entries/${widget.entryId}', data: payload);
      }
      if (!mounted) return;
      context.go('/journal');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? ((e.response!.data['message'] ?? tr('Save failed')) as String)
          : tr('Save failed.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (widget.entryId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Delete this entry?')),
        content: Text(tr('This can\'t be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tr('Keep'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FriendColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dio = ref.read(dioProvider);
    await dio.delete('/journal-entries/${widget.entryId}');
    if (!mounted) return;
    context.go('/journal');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FriendTabScaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return FriendTabScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 24),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          FriendPageHeader(
            eyebrow: tr('Journal'),
            title: widget.entryId == null ? tr('New entry') : tr('Edit entry'),
            subtitle: tr('Your entries are encrypted at rest.'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.entryId != null) ...[
                  FriendIconChip(
                    icon: Icons.delete_outline,
                    tooltip: tr('Delete'),
                    onPressed: _delete,
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 18)),
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? tr('Saving…') : tr('Save')),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: tr('Title (optional)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _body,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: tr('What\'s on your mind?'),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MoodPicker(
                    value: _mood,
                    onChanged: (v) => setState(() => _mood = v),
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

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(tr('Mood'), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 12),
        for (var i = 1; i <= 7; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == i,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(value == i ? null : i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: value == null || value == i ? 1 : 0.45,
                    child: FreudArt.moodFaceAt(valence: (i - 1) / 6, size: 34, selected: value == i),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
