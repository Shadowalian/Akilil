import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  String _activeAssessment = 'gad7';
  // Nothing is pre-answered: a screener only means something if you fill it in.
  final Map<int, int> _gad7Answers = {};
  final Map<int, int> _phq9Answers = {};
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _lastResult = prefs.getString('akilil_screener_last_$_activeAssessment'));
    } catch (_) {}
  }

  Future<void> _saveResult(int score, String severity) async {
    final line = '$score · $severity · ${DateTime.now().toLocal().toString().substring(0, 10)}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('akilil_screener_last_$_activeAssessment', line);
    } catch (_) {}
    if (mounted) setState(() => _lastResult = line);
  }

  static const List<String> _scaleLabels = [
    'Not at all (0)',
    'Several days (1)',
    'More than half the days (2)',
    'Nearly every day (3)',
  ];

  int _calculateScore(Map<int, int> answers) {
    return answers.values.fold(0, (sum, val) => sum + val);
  }

  (String, String, Color) _interpretScore(String type, int score) {
    if (type == 'gad7') {
      if (score <= 4) return ('Minimal Anxiety', 'Your symptoms reflect minimal nervous tension.', FriendColors.green);
      if (score <= 9) return ('Mild Anxiety', 'Mild anxiety. Breathing exercises and thought records can help.', FriendColors.primaryDeep);
      if (score <= 14) return ('Moderate Anxiety', 'Moderate anxiety. Talking with a professional regularly is likely to help.', FriendColors.accent);
      return ('Severe Anxiety', 'Severe anxiety. Please book a session with a licensed professional soon.', FriendColors.error);
    } else {
      if (score <= 4) return ('Minimal Depression', 'No significant depressive patterns indicated.', FriendColors.green);
      if (score <= 9) return ('Mild Depression', 'Mild low mood. Daily physical movement and gratitude logging can help lift energy.', FriendColors.primaryDeep);
      if (score <= 14) return ('Moderate Depression', 'Moderate depression symptoms. Continued regular counseling sessions recommended.', FriendColors.accent);
      if (score <= 19) return ('Moderately Severe', 'Moderately severe. Please book a session with a licensed professional.', FriendColors.accentDeep);
      return ('Severe Depression', 'Severe. Please speak with a licensed professional as soon as you can.', FriendColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = SeedData.assessments[_activeAssessment] as Map<String, dynamic>;
    final questions = (meta['questions'] as List).cast<String>();
    final answers = _activeAssessment == 'gad7' ? _gad7Answers : _phq9Answers;
    final score = _calculateScore(answers);
    final complete = answers.length == questions.length;
    final (severityTitle, severityDesc, severityColor) = complete
        ? _interpretScore(_activeAssessment, score)
        : ('${answers.length} of ${questions.length} answered', 'Answer every question to see your result.', FriendColors.textMuted);
    // PHQ-9 item 9 asks about self-harm. Any answer above "not at all"
    // means we stop and offer help, whatever the total score.
    final selfHarmFlag = _activeAssessment == 'phq9' && (answers[8] ?? 0) > 0;

    return FriendPageScaffold(
      eyebrow: 'Check-ins',
      title: 'How have you been?',
      subtitle:
          'Two short, widely used questionnaires (GAD-7 and PHQ-9) to track anxiety and low mood over time.',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector between GAD-7 and PHQ-9
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  title: 'GAD-7 (Anxiety)',
                  isSelected: _activeAssessment == 'gad7',
                  onTap: () {
                    setState(() => _activeAssessment = 'gad7');
                    _loadLast();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TabButton(
                  title: 'PHQ-9 (Depression)',
                  isSelected: _activeAssessment == 'phq9',
                  onTap: () {
                    setState(() => _activeAssessment = 'phq9');
                    _loadLast();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (selfHarmFlag) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FriendColors.errorContainer,
                borderRadius: BorderRadius.circular(FriendRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thank you for being honest. You don't have to carry this alone.",
                    style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w800, color: FriendColors.onErrorContainer),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'If you might act on these thoughts, call 907 for an ambulance now, or go to the nearest hospital. '
                    'Otherwise, please talk to someone today.',
                    style: GoogleFonts.urbanist(fontSize: 13, height: 1.4, color: FriendColors.onErrorContainer),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/crisis'),
                    style: FilledButton.styleFrom(backgroundColor: FriendColors.error),
                    icon: const Icon(Icons.support_rounded),
                    label: const Text('Get support now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Score Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FriendColors.surface,
              borderRadius: BorderRadius.circular(FriendRadii.card),
              border: Border.all(color: severityColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: FriendElevation.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      complete ? '$score' : '–',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: severityColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        severityTitle,
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        severityDesc,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          height: 1.4,
                          color: FriendColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            meta['subtitle'] as String? ?? '',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FriendColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Questionnaire List
          for (var i = 0; i < questions.length; i++) ...[
            CandyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${questions[i]}',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var val = 0; val < _scaleLabels.length; val++) ...[
                    InkWell(
                      onTap: () => setState(() => answers[i] = val),
                      borderRadius: BorderRadius.circular(FriendRadii.small),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: val,
                              groupValue: answers[i],
                              activeColor: FriendColors.primary,
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setState(() => answers[i] = newVal);
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                _scaleLabels[val],
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: answers[i] == val
                                      ? FriendColors.primaryDeep
                                      : FriendColors.textPrimary,
                                  fontWeight: answers[i] == val
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),

          if (_lastResult != null) ...[
            Text(
              'Last time: $_lastResult',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
            ),
            const SizedBox(height: 10),
          ],
          FriendGlowButton(
            label: 'Save result',
            icon: Icons.check_circle_rounded,
            expanded: true,
            onPressed: !complete
                ? null
                : () async {
                    await _saveResult(score, severityTitle);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved on this phone. Check in again in two weeks to see the trend.')),
                    );
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'This is a screening tool, not a diagnosis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textMuted),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? FriendColors.primary : FriendColors.surface,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FriendRadii.pill),
            border: Border.all(
              color: isSelected ? FriendColors.primary : FriendColors.border,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : FriendColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
