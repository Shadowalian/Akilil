import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';
import 'worksheet_store.dart';
import 'box_breathing_dialog.dart';

class WorksheetsScreen extends ConsumerStatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  ConsumerState<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends ConsumerState<WorksheetsScreen> {
  // Internal values stay English (they match the data); labels are translated.
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'CBT Tools',
    'Anxiety & Panic',
    'Mindfulness',
    'Boundaries & Relationships',
    'Depression & Mood',
  ];

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(worksheetStoreProvider);
    final allWorksheets = [
      for (final w in SeedData.worksheets) {...w, 'is_completed': done[w['id']]?.containsKey('_completed_at') ?? false},
    ];
    final filtered = _selectedCategory == 'All'
        ? allWorksheets
        : allWorksheets.where((w) => w['category'] == _selectedCategory).toList();

    return FriendPageScaffold(
      eyebrow: tr('Tools'),
      title: tr('Worksheets'),
      subtitle:
          tr('Short, well-tested exercises you can do on your own or alongside your sessions.'),
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CandyCard(
            onTap: () => BoxBreathingDialog.show(context),
            child: Row(
              children: [
                const FriendIconTile(icon: Icons.air_rounded, color: FriendColors.primary, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Feeling anxious right now?'), style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        tr('1-minute guided visual box breathing to quiet your heart rate.'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => BoxBreathingDialog.show(context),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: Text(tr('Breathe')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = _categories[i];
                return FriendStitchFilterPill(
                  label: tr(c),
                  selected: _selectedCategory == c,
                  onTap: () => setState(() => _selectedCategory = c),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Worksheets List
          for (final w in filtered) ...[
            _WorksheetCard(
              worksheet: w,
              onTap: () {
                if (w['is_interactive'] == true) {
                  BoxBreathingDialog.show(context);
                } else {
                  context.push('/worksheets/${w['id']}');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _WorksheetCard extends StatelessWidget {
  const _WorksheetCard({required this.worksheet, required this.onTap});
  final Map<String, dynamic> worksheet;
  final VoidCallback onTap;

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'edit_note_rounded':
        return Icons.edit_note_rounded;
      case 'psychology_alt_rounded':
        return Icons.psychology_alt_rounded;
      case 'air_rounded':
        return Icons.air_rounded;
      case 'spa_rounded':
        return Icons.spa_rounded;
      case 'shield_outlined':
        return Icons.shield_outlined;
      case 'favorite_border_rounded':
        return Icons.favorite_border_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = tr(worksheet['title'] as String? ?? '');
    final category = tr(worksheet['category'] as String? ?? '');
    final tag = tr(worksheet['tag'] as String? ?? '');
    final desc = tr(worksheet['description'] as String? ?? '');
    final isCompleted = worksheet['is_completed'] == true;
    final icon = _getIcon(worksheet['icon'] as String?);

    final theme = Theme.of(context);
    return CandyCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FriendIconTile(icon: icon, color: isCompleted ? FriendColors.success : FriendColors.primary, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  [category, if (isCompleted) tr('Completed') else if (tag.isNotEmpty) tag].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(color: isCompleted ? FriendColors.success : null),
                ),
                const SizedBox(height: 8),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.chevron_right_rounded, size: 22, color: FriendColors.textMuted),
          ),
        ],
      ),
    );
  }
}
