import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';
import 'box_breathing_dialog.dart';
import 'worksheet_store.dart';

class WorksheetDetailScreen extends ConsumerStatefulWidget {
  const WorksheetDetailScreen({super.key, required this.worksheetId});
  final String worksheetId;

  @override
  ConsumerState<WorksheetDetailScreen> createState() => _WorksheetDetailScreenState();
}

class _WorksheetDetailScreenState extends ConsumerState<WorksheetDetailScreen> {
  late Map<String, dynamic> _worksheet;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  String? _selectedDistortion;

  static const List<String> _distortions = [
    'All-or-Nothing Thinking',
    'Catastrophizing',
    'Jumping to Conclusions',
    'Overgeneralization',
    'Mental Filter (Negative Bias)',
    'Disqualifying the Positive',
    'Emotional Reasoning',
    '“Should” Statements',
    'Personalization',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorksheet();
  }

  void _loadWorksheet() {
    final list = SeedData.worksheets;
    _worksheet = list.firstWhere(
      (w) => w['id'] == widget.worksheetId,
      orElse: () => list.first,
    );

    // Copy so marking it completed never touches the shared template.
    _worksheet = Map<String, dynamic>.from(_worksheet);
    final saved = ref.read(worksheetStoreProvider)[widget.worksheetId] ?? const {};
    _worksheet['is_completed'] = saved.containsKey('_completed_at');
    final fields = (_worksheet['fields'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final f in fields) {
      final id = f['id'] as String;
      final val = saved[id] ?? '';
      _controllers[id] = TextEditingController(text: val);
      if (f['type'] == 'distortion_picker') {
        _selectedDistortion = val.isNotEmpty ? val : null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(worksheetStoreProvider.notifier).save(widget.worksheetId, {
      for (final e in _controllers.entries) e.key: e.value.text,
      if (_selectedDistortion != null)
        for (final f in ((_worksheet['fields'] as List?) ?? const []))
          if (f['type'] == 'distortion_picker') f['id'] as String: _selectedDistortion!,
    });
    if (!mounted) return;

    setState(() {
      _worksheet['is_completed'] = true;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: FriendColors.primaryDeep,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Saved on this phone. Bring it to your next session if you want to talk it through.',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _worksheet['title'] as String? ?? 'Therapy Worksheet';
    final desc = _worksheet['description'] as String? ?? '';
    final category = _worksheet['category'] as String? ?? 'CBT Tools';
    final isInteractive = _worksheet['is_interactive'] == true;
    final isCompleted = _worksheet['is_completed'] == true;
    final fields = (_worksheet['fields'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(
        backgroundColor: FriendColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: FriendColors.textPrimary,
          ),
        ),
        actions: [
          if (isCompleted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FriendColors.greenSoft,
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: FriendColors.primaryDeep),
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
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Clinical Header Banner
          CandyCard(
            tint: FriendColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FriendColors.primaryLight,
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: FriendColors.primaryDeep,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.verified_rounded, size: 16, color: FriendColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Self-guided',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: FriendColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // If interactive box breathing tool
          if (isInteractive) ...[
            CandyCard(
              child: Column(
                children: [
                  const Icon(Icons.air_rounded, size: 48, color: FriendColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Ready for Box Breathing?',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap below to launch the full animated visual breathing guide with audio timing cues.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FriendGlowButton(
                    label: 'Start Breathing Exercise',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => BoxBreathingDialog.show(context),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Form Fields
            for (final f in fields) ...[
              _buildField(f),
              const SizedBox(height: 18),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: FriendColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your answers stay on this phone. Nobody else sees them unless you choose to share.',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            FriendGlowButton(
              label: _saving ? 'Saving…' : 'Save',
              expanded: true,
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> f) {
    final id = f['id'] as String;
    final label = f['label'] as String;
    final placeholder = f['placeholder'] as String? ?? '';
    final type = f['type'] as String? ?? 'text';

    if (type == 'distortion_picker') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FriendColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _distortions.map((d) {
              final isSel = _selectedDistortion == d;
              return ChoiceChip(
                label: Text(d),
                selected: isSel,
                onSelected: (sel) {
                  if (sel) {
                    setState(() {
                      _selectedDistortion = d;
                      _controllers[id]?.text = d;
                    });
                  }
                },
                selectedColor: FriendColors.primaryLight,
                labelStyle: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? FriendColors.primaryDeep : FriendColors.textPrimary,
                ),
                backgroundColor: FriendColors.surface,
                side: BorderSide(
                  color: isSel ? FriendColors.primary : FriendColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    final controller = _controllers[id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: FriendColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            height: 1.45,
            color: FriendColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.urbanist(
              fontSize: 13,
              color: FriendColors.textMuted,
            ),
            filled: true,
            fillColor: FriendColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FriendRadii.small),
              borderSide: const BorderSide(color: FriendColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FriendRadii.small),
              borderSide: const BorderSide(color: FriendColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FriendRadii.small),
              borderSide: const BorderSide(color: FriendColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
