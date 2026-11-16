import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import '../../l10n/app_locale.dart';
import '../core_data/seed_data.dart';

const _ethiopicFallback = ['NotoSansEthiopic'];

TextStyle _geist({
  double? size,
  FontWeight weight = FontWeight.w600,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Geist',
    fontFamilyFallback: _ethiopicFallback,
    fontSize: size,
    fontWeight: weight,
    color: color ?? FriendColors.textPrimary,
    height: height,
  );
}

class SafetyPlanScreen extends ConsumerStatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  ConsumerState<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends ConsumerState<SafetyPlanScreen> {
  late List<String> _warningSigns;
  late List<String> _internalCoping;
  late List<Map<String, String>> _trustedPeople;
  late List<String> _safeEnvironment;

  @override
  void initState() {
    super.initState();
    final p = SeedData.safetyPlan;
    _warningSigns = List<String>.from(p['warning_signs'] as List);
    _internalCoping = List<String>.from(p['internal_coping'] as List);
    _trustedPeople = (p['trusted_people'] as List)
        .map((x) => Map<String, String>.from(x as Map))
        .toList();
    _safeEnvironment = List<String>.from(p['safe_environment'] as List);
  }

  void _addWarningSign() async {
    final text = await _promptUser('Add Warning Sign', 'e.g. Trouble sleeping past 3 AM');
    if (text != null && text.isNotEmpty) {
      setState(() => _warningSigns.add(text));
    }
  }

  void _addCopingStrategy() async {
    final text = await _promptUser('Add Coping Strategy', 'e.g. 10-minute breathwork');
    if (text != null && text.isNotEmpty) {
      setState(() => _internalCoping.add(text));
    }
  }

  Future<String?> _promptUser(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: _geist(weight: FontWeight.w800)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: FriendColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
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
          s.mySafetyPlan,
          style: _geist(size: 18, weight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CandyCard(
            tint: FriendColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: FriendColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Co-Created with Dr. Maya Lin',
                      style: _geist(
                        size: 12,
                        weight: FontWeight.w700,
                        color: FriendColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your 6-Step Safety Protocol',
                  style: _geist(
                    size: 20,
                    weight: FontWeight.w800,
                    color: FriendColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Having a predefined plan removes cognitive load during acute emotional distress or overwhelm. Keep this accessible.',
                  style: _geist(
                    size: 13,
                    height: 1.45,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Step 1: Warning Signs
          _buildStepCard(
            stepNumber: 1,
            title: 'Warning Signs of Overwhelm',
            subtitle: 'Thoughts, moods, or bodily sensations that signal distress is escalating.',
            items: _warningSigns,
            onAdd: _addWarningSign,
            onRemove: (idx) => setState(() => _warningSigns.removeAt(idx)),
          ),
          const SizedBox(height: 20),

          // Step 2: Internal Coping Strategies
          _buildStepCard(
            stepNumber: 2,
            title: 'Internal Coping Tools (Without Calling Anyone)',
            subtitle: 'Things you can do solo to calm your nervous system down.',
            items: _internalCoping,
            onAdd: _addCopingStrategy,
            onRemove: (idx) => setState(() => _internalCoping.removeAt(idx)),
          ),
          const SizedBox(height: 20),

          // Step 3: Trusted People
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _stepBadge(3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'People I Can Reach Out To',
                        style: _geist(
                          size: 16,
                          weight: FontWeight.w800,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Friends, partners, or family members who provide calm, grounded distraction or care.',
                  style: _geist(
                    size: 12,
                    color: FriendColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (final p in _trustedPeople) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: FriendColors.background,
                      borderRadius: BorderRadius.circular(FriendRadii.small),
                      border: Border.all(color: FriendColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: FriendColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p['name'] ?? '',
                            style: _geist(
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          p['phone'] ?? '',
                          style: _geist(
                            size: 13,
                            color: FriendColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 4: Making Environment Safe
          _buildStepCard(
            stepNumber: 4,
            title: 'Making My Environment Safe',
            subtitle: 'Immediate steps to minimize stress inputs and sensory triggers.',
            items: _safeEnvironment,
            onAdd: () async {
              final text = await _promptUser('Add Environmental Step', 'e.g. Dim lights');
              if (text != null && text.isNotEmpty) {
                setState(() => _safeEnvironment.add(text));
              }
            },
            onRemove: (idx) => setState(() => _safeEnvironment.removeAt(idx)),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _stepBadge(int num) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: FriendColors.primary,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
      ),
      child: Center(
        child: Text(
          '$num',
          style: _geist(
            size: 14,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required List<String> items,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
  }) {
    return CandyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepBadge(stepNumber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: _geist(
                    size: 16,
                    weight: FontWeight.w800,
                    color: FriendColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: FriendColors.primary),
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: _geist(
              size: 12,
              color: FriendColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: FriendColors.background,
                borderRadius: BorderRadius.circular(FriendRadii.small),
                border: Border.all(color: FriendColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: FriendColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: _geist(
                        size: 13,
                        weight: FontWeight.w600,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => onRemove(i),
                    child: const Icon(Icons.close_rounded, size: 16, color: FriendColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
