import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedCategory = 'All';

  final List<String> _categories = [
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
      eyebrow: 'Tools',
      title: 'Worksheets',
      subtitle:
          'Short, well-tested exercises you can do on your own or alongside your sessions.',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Launch Banner for Box Breathing
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A9FC4), Color(0xFF0F7FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(FriendRadii.card),
              boxShadow: [
                BoxShadow(
                  color: FriendColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.air_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feeling Anxious Right Now?',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1-minute guided visual box breathing to quiet your heart rate.',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => BoxBreathingDialog.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: FriendColors.primaryDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(
                    'Breathe',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSel = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSel,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedCategory = c);
                    },
                    selectedColor: FriendColors.primaryLight,
                    backgroundColor: FriendColors.surface,
                    labelStyle: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? FriendColors.primaryDeep : FriendColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSel ? FriendColors.primary : FriendColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

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
    final title = worksheet['title'] as String? ?? '';
    final category = worksheet['category'] as String? ?? '';
    final tag = worksheet['tag'] as String? ?? '';
    final desc = worksheet['description'] as String? ?? '';
    final isCompleted = worksheet['is_completed'] == true;
    final icon = _getIcon(worksheet['icon'] as String?);

    return CandyCard(
      tint: FriendColors.primary,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FriendColors.primaryLight,
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                ),
                child: Icon(icon, color: FriendColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FriendColors.greenSoft,
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 12, color: FriendColors.primaryDeep),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FriendColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                )
              else if (tag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FriendColors.background,
                    border: Border.all(color: FriendColors.border),
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FriendColors.primaryDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              height: 1.4,
              color: FriendColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                isCompleted ? 'Review & Edit' : 'Open Exercise',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: FriendColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: FriendColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
