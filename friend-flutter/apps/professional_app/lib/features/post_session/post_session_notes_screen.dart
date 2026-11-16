import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

/// Quick summary form the pro lands on after ending a session.
/// Notes are required; action items are typed as a comma-separated
/// line and split into the array the API expects.
class PostSessionNotesScreen extends ConsumerStatefulWidget {
  const PostSessionNotesScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  ConsumerState<PostSessionNotesScreen> createState() => _S();
}

class _S extends ConsumerState<PostSessionNotesScreen> {
  final _notes = TextEditingController();
  final _actions = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    _actions.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sessions');
    }
  }

  Future<void> _submit() async {
    final notes = _notes.text.trim();
    if (notes.isEmpty) {
      setState(() => _error = 'Add a few notes before saving.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final items = _actions.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    try {
      await ref.read(dioProvider).post(
        '/appointments/${widget.appointmentId}/notes',
        data: {
          'notes': notes,
          if (items.isNotEmpty) 'action_items': items,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session notes saved.')),
      );
      _leave();
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() => _error = data is Map && data['message'] is String
          ? data['message'] as String
          : "Couldn't save your notes.");
    } catch (_) {
      setState(() => _error = "Couldn't save your notes.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session notes'),
        actions: [
          TextButton(onPressed: _busy ? null : _leave, child: const Text('Skip')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How did it go?',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text(
                  'Private to you — clients never see these notes.',
                  style: TextStyle(color: FriendColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  minLines: 5,
                  maxLines: 12,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _actions,
                  decoration: const InputDecoration(
                    labelText: 'Action items (optional)',
                    hintText: 'Breathing exercise, journal daily',
                    helperText: 'Separate each item with a comma.',
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Save notes'),
          ),
        ],
      ),
    );
  }
}
