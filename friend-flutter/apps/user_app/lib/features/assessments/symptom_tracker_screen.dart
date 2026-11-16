import 'package:flutter/material.dart';
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
  final Map<int, int> _gad7Answers = {0: 1, 1: 1, 2: 2, 3: 1, 4: 1, 5: 1, 6: 1};
  final Map<int, int> _phq9Answers = {0: 1, 1: 0, 2: 1, 3: 2, 4: 0, 5: 1, 6: 0, 7: 1, 8: 0};

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
      if (score <= 9) return ('Mild Anxiety', 'Mild anxiety symptoms present. CBT thought records and daily box breathing are recommended.', FriendColors.primaryDeep);
      if (score <= 14) return ('Moderate Anxiety', 'Moderate anxiety detected. Weekly video therapy with Dr. Maya Lin is highly advised.', FriendColors.accent);
      return ('Severe Anxiety', 'High anxiety load. Please discuss immediate somatic down-regulation and coping protocols with your counselor.', FriendColors.error);
    } else {
      if (score <= 4) return ('Minimal Depression', 'No significant depressive patterns indicated.', FriendColors.green);
      if (score <= 9) return ('Mild Depression', 'Mild low mood. Daily physical movement and gratitude logging can help lift energy.', FriendColors.primaryDeep);
      if (score <= 14) return ('Moderate Depression', 'Moderate depression symptoms. Continued regular counseling sessions recommended.', FriendColors.accent);
      if (score <= 19) return ('Moderately Severe', 'Significant depressive fatigue. Ensure regular communication with Dr. Lin.', FriendColors.accentDeep);
      return ('Severe Depression', 'High severity score. Immediate clinical consultation advised.', FriendColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = SeedData.assessments[_activeAssessment] as Map<String, dynamic>;
    final questions = (meta['questions'] as List).cast<String>();
    final answers = _activeAssessment == 'gad7' ? _gad7Answers : _phq9Answers;
    final score = _calculateScore(answers);
    final (severityTitle, severityDesc, severityColor) = _interpretScore(_activeAssessment, score);

    return FriendPageScaffold(
      eyebrow: 'Clinical Screeners',
      title: 'Symptom Checkers',
      subtitle:
          'Standardized PHQ-9 & GAD-7 clinical questionnaires to track anxiety and mood progression over time.',
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
                  onTap: () => setState(() => _activeAssessment = 'gad7'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TabButton(
                  title: 'PHQ-9 (Depression)',
                  isSelected: _activeAssessment == 'phq9',
                  onTap: () => setState(() => _activeAssessment = 'phq9'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                      '$score',
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
                              groupValue: answers[i] ?? 0,
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

          FriendGlowButton(
            label: 'Save & Share Assessment with Counselor',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: FriendColors.primaryDeep,
                  content: Text(
                    'Assessment saved. Dr. Maya Lin has been notified of your updated score ($score).',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
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
