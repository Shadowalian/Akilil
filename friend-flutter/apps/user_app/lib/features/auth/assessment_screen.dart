import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import '../discovery/pillar_provider.dart';
import 'onboarding_prefs.dart';

/// Clinical matching intake — Stitch progress, intent chips, PHQ-style triage.
class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  static const _totalSteps = 4;

  int _step = 0;
  final _answers = <int?>[null, null, null];
  final _concerns = <int>{};
  int _genderPref = 0;
  final _languages = <int>{0};
  final _modalities = <int>{0};

  static const _concernItems = [
    (Icons.psychology_rounded, 'Cognitive Overwhelm & Burnout', 'Mental exhaustion, chronic strain'),
    (Icons.monitor_heart_outlined, 'Grief & Somatic Tension', 'Physical holding, bereavement'),
    (Icons.trending_up_rounded, 'Life Transitions & Career Pressure', 'Relocation, milestones, decisions'),
    (Icons.diversity_1_outlined, 'Relationship & Family Dynamics', 'Attachment, boundaries, conflict'),
    (Icons.bedtime_outlined, 'Sleep Regulation & Restlessness', 'Insomnia, nocturnal overactivation'),
  ];

  static const _phqOptions = [
    ('Not at all', '0 pts'),
    ('Several days', '+1 pt'),
    ('More than half the days', '+2 pts'),
    ('Nearly every day', '+3 pts'),
  ];

  List<_Q> _questions(S s) => [
        const _Q(
          'How have you been feeling lately?',
          'There is no wrong answer here.',
          [
            'Overwhelmed',
            'A bit low',
            'Okay',
            'Mostly good',
            'Really well',
          ],
        ),
        _Q(
          'What kind of support are you looking for?',
          'This sets the path we open first.',
          [
            s.spiritualPsychiatry,
            s.psychiatry,
            s.cooking,
            'Not sure yet',
          ],
        ),
        const _Q(
          'How would you prefer to connect?',
          'You can change this any time.',
          [
            'Private video sessions',
            'Journaling first',
            'Community circles',
            'A mix of all three',
          ],
        ),
      ];

  String get _stepLabel => switch (_step) {
        0 => 'Step 1 of $_totalSteps • What brings you here',
        1 => 'Step 2 of $_totalSteps • How you feel',
        2 => 'Step 3 of $_totalSteps • Your path',
        _ => 'Step 4 of $_totalSteps • Connection Preference',
      };

  bool get _canContinue => switch (_step) {
        0 => _concerns.isNotEmpty,
        1 => _answers[0] != null,
        2 => _answers[1] != null,
        _ => _answers[2] != null,
      };

  Future<void> _finish() async {
    final pathAnswer = _answers[1];
    if (pathAnswer != null && pathAnswer < 3) {
      final slug = AkililPillars.all[pathAnswer].slug;
      ref.read(discoverPillarProvider.notifier).state = slug;
    }
    // Kept until the account exists, then sent to the matching API.
    await savePendingIntake({
      'pillar': pathAnswer != null && pathAnswer < 3 ? AkililPillars.all[pathAnswer].slug : null,
      'answers': {
        'concerns': [for (final i in _concerns) _concernItems[i].$2],
        'feeling': _answers[0],
        'connect': _answers[2],
      },
    });
    if (!mounted) return;
    context.go(AppRoutes.register);
    await ref.read(onboardingDoneProvider.notifier).complete();
  }

  void _continue() {
    if (!_canContinue) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final questions = _questions(s);
    final isLast = _step == _totalSteps - 1;

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: FriendStitchGlassHeader(
        title: 'A few questions',
        onBack: _back,
        onSos: () => context.push(AppRoutes.crisis),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FriendStitchProgressTrack(
            step: _step,
            totalSteps: _totalSteps,
            stepLabel: _stepLabel,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FriendLayout.horizontal,
                0,
                FriendLayout.horizontal,
                120,
              ),
              children: [
                if (_step <= 1) ...[
                  const FriendVaultBadge(),
                  const SizedBox(height: 12),
                  Text(
                    'Help us find the right person.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: FriendTypeScale.headlineMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your answers help us suggest people who fit. Only you and the professional you book can see them.',
                    style: GoogleFonts.inter(
                      fontSize: FriendTypeScale.bodyMedium,
                      height: 1.45,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                switch (_step) {
                  0 => _buildConcernsStep(),
                  1 => _buildPhqStep(questions[0]),
                  2 => _buildModalityStep(questions[1]),
                  _ => _buildConnectionStep(questions[2]),
                },
              ],
            ),
          ),
          FriendStitchStickyBar(
            onBack: _step > 0 ? _back : null,
            primaryLabel: isLast ? 'Create Account' : s.continueLabel,
            primaryEnabled: _canContinue,
            onPrimary: _canContinue ? _continue : null,
          ),
        ],
      ),
    );
  }

  Widget _buildConcernsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'What brings you to Akilil today?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: FriendTypeScale.headlineSmall,
                  fontWeight: FontWeight.w600,
                  color: FriendColors.textPrimary,
                ),
              ),
            ),
            Text(
              'SELECT ALL',
              style: GoogleFonts.inter(
                fontSize: FriendTypeScale.micro,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: FriendColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _concernItems.length; i++) ...[
          FriendIntentChip(
            icon: _concernItems[i].$1,
            title: _concernItems[i].$2,
            subtitle: _concernItems[i].$3,
            selected: _concerns.contains(i),
            onTap: () {
              setState(() {
                if (_concerns.contains(i)) {
                  _concerns.remove(i);
                } else {
                  _concerns.add(i);
                }
              });
            },
          ),
          if (i < _concernItems.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPhqStep(_Q q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FriendColors.recessed,
            borderRadius: BorderRadius.circular(FriendRadii.large),
            boxShadow: FriendElevation.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const FriendLivePulse(size: 8),
                  const SizedBox(width: 8),
                  Text(
                    'STANDARDIZED CLINICAL TRIAGE',
                    style: GoogleFonts.inter(
                      fontSize: FriendTypeScale.micro,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: FriendColors.accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'PHQ-4 SCALE',
                    style: GoogleFonts.inter(
                      fontSize: FriendTypeScale.micro,
                      fontWeight: FontWeight.w600,
                      color: FriendColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Over the last 2 weeks, how often have you felt down, depressed, or hopeless?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: FriendTypeScale.headlineSmall,
                  fontWeight: FontWeight.w600,
                  color: FriendColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                q.hint,
                style: GoogleFonts.inter(
                  fontSize: FriendTypeScale.bodySmall,
                  color: FriendColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < q.options.length && i < _phqOptions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FriendPhqRadioOption(
                    label: q.options[i],
                    pointsLabel: _phqOptions[i].$2,
                    selected: _answers[0] == i,
                    onTap: () => setState(() => _answers[0] = i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModalityStep(_Q q) {
    const modalityLabels = [
      'Cognitive Behavioral (CBT)',
      'Somatic & Breathwork',
      'Psychodynamic',
      'Empathetic Peer Listening',
    ];
    const genderLabels = ['No preference', 'Female', 'Male'];
    const langLabels = ['English', 'Amharic', 'Afaan Oromoo', 'Tigrinya'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Therapeutic Modality & Practitioner',
          style: GoogleFonts.plusJakartaSans(
            fontSize: FriendTypeScale.headlineSmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Filter your clinical network by therapeutic methodology and communication comfort.',
          style: GoogleFonts.inter(
            fontSize: FriendTypeScale.bodySmall,
            color: FriendColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'PREFERRED APPROACH',
          style: GoogleFonts.inter(
            fontSize: FriendTypeScale.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: FriendColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < modalityLabels.length; i++)
              FriendStitchFilterPill(
                label: modalityLabels[i],
                selected: _modalities.contains(i),
                icon: i == 0 ? Icons.spa_outlined : null,
                onTap: () {
                  setState(() {
                    if (_modalities.contains(i)) {
                      _modalities.remove(i);
                    } else {
                      _modalities.add(i);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'PRACTITIONER GENDER',
          style: GoogleFonts.inter(
            fontSize: FriendTypeScale.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: FriendColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: FriendColors.surfaceContainer,
            borderRadius: BorderRadius.circular(FriendRadii.medium),
          ),
          child: Row(
            children: [
              for (var i = 0; i < genderLabels.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: _genderPref == i
                          ? FriendColors.surfaceLowest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(FriendRadii.small),
                      elevation: _genderPref == i ? 1 : 0,
                      child: InkWell(
                        onTap: () => setState(() => _genderPref = i),
                        borderRadius: BorderRadius.circular(FriendRadii.small),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            genderLabels[i],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: FriendTypeScale.caption,
                              fontWeight:
                                  _genderPref == i ? FontWeight.w600 : FontWeight.w500,
                              color: _genderPref == i
                                  ? FriendColors.textPrimary
                                  : FriendColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'LANGUAGE FLUENCY',
          style: GoogleFonts.inter(
            fontSize: FriendTypeScale.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: FriendColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < langLabels.length; i++)
              FriendStitchFilterPill(
                label: langLabels[i],
                selected: _languages.contains(i),
                roundedRect: true,
                icon: i == 0 ? Icons.translate_rounded : null,
                onTap: () {
                  setState(() {
                    if (_languages.contains(i)) {
                      _languages.remove(i);
                    } else {
                      _languages.add(i);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          q.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: FriendTypeScale.headlineSmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FriendPhqRadioOption(
              label: q.options[i],
              pointsLabel: '',
              selected: _answers[1] == i,
              onTap: () => setState(() => _answers[1] = i),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStep(_Q q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          q.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: FriendTypeScale.headlineMedium,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          q.hint,
          style: GoogleFonts.inter(
            fontSize: FriendTypeScale.bodyMedium,
            color: FriendColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FriendIntentChip(
              icon: Icons.check_circle_outline_rounded,
              title: q.options[i],
              subtitle: '',
              selected: _answers[2] == i,
              onTap: () => setState(() => _answers[2] = i),
            ),
          ),
      ],
    );
  }
}

class _Q {
  const _Q(this.title, this.hint, this.options);
  final String title;
  final String hint;
  final List<String> options;
}
