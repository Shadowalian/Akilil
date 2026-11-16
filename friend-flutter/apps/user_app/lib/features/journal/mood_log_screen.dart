import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../brand/freud_art.dart';

/// Freud mood tracker — large 1–7 selector, optional note, pill CTA.
class MoodLogScreen extends ConsumerStatefulWidget {
  const MoodLogScreen({super.key});

  @override
  ConsumerState<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends ConsumerState<MoodLogScreen> {
  int? _mood;
  final _note = TextEditingController();
  bool _busy = false;
  String? _feedback;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    if (_mood == null) return;
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/mood-logs', data: {
        'mood': _mood,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      setState(() {
        _feedback = 'Logged. See you tomorrow.';
        _mood = null;
        _note.clear();
      });
    } on DioException {
      setState(() => _feedback = "Couldn't save. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FriendPageScaffold(
      eyebrow: 'Check in',
      title: 'How are you?',
      subtitle: 'A quiet moment. Just for you.',
      trailing: FriendIconChip(
        icon: Icons.insights_outlined,
        tooltip: 'Analytics',
        onPressed: () => context.go('/mood/analytics'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CandyCard(
            tint: FriendColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
            child: Column(
              children: [
                Text(
                  _mood == null ? 'Tap a face' : _labelFor(_mood!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 1; i <= 7; i++)
                      GestureDetector(
                        onTap: () => setState(() => _mood = i),
                        child: _MoodTile(level: i, selected: _mood == i),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Optional note',
              hintText: 'Anything else you want to capture?',
              filled: true,
              fillColor: FriendColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                borderSide: const BorderSide(color: FriendColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                borderSide: const BorderSide(color: FriendColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                borderSide: const BorderSide(color: FriendColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FriendGlowButton(
            label: 'Save mood',
            expanded: true,
            onPressed: _mood == null || _busy ? null : _log,
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 16),
            Text(
              _feedback!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: FriendColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _labelFor(int mood) => switch (mood) {
        1 => 'Very low',
        2 => 'Low',
        3 => 'A bit down',
        4 => 'Okay',
        5 => 'Good',
        6 => 'Great',
        _ => 'Excellent',
      };
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({required this.level, required this.selected});
  final int level;
  final bool selected;

  static const _levels = 7;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      scale: selected ? 1.06 : 1.0,
      child: FreudArt.moodFaceAt(
        valence: (level - 1) / (_levels - 1),
        size: 56,
        selected: selected,
      ),
    );
  }
}
