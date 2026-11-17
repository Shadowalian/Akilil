import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

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
        _body.text = data['body_md'] as String? ?? '';
        _mood = data['mood_at_write'] as int?;
      });
    } catch (_) {
      // Will show empty editor if load fails; the user can re-type.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Add a title or some text first.'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'title': _title.text.trim(),
        'body_md': _body.text,
        if (_mood != null) 'mood_at_write': _mood,
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          FriendPageHeader(
            eyebrow: tr('Journal'),
            title: widget.entryId == null ? 'New entry' : tr('Edit entry'),
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
                FriendGlowButton(
                  label: _busy ? 'Saving…' : tr('Save'),
                  onPressed: _busy ? null : _save,
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

  static const _faces = ['😔', '😕', '😐', '🙂', '😊', '😄', '✨'];
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (var i = 0; i < _faces.length; i++)
          GestureDetector(
            onTap: () => onChanged(value == i + 1 ? null : i + 1),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: value == i + 1
                    ? FriendColors.primary.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: value == i + 1 ? FriendColors.primary : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(_faces[i], style: const TextStyle(fontSize: 24))),
            ),
          ),
      ],
    );
  }
}
