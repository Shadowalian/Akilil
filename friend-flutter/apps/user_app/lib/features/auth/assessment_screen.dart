import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// English values are stored and sent to the server; labels are
  /// translated only when shown.
  static const List<(IconData, String, String)> _concernItems = [
    (Icons.battery_alert_outlined, 'Overwhelmed or burnt out', 'Tired all the time, too much on your plate'),
    (Icons.favorite_border_rounded, 'Grief and loss', 'Losing someone, or something important to you'),
    (Icons.alt_route_rounded, 'Big changes or work pressure', 'A move, a new role, a hard decision'),
    (Icons.people_outline_rounded, 'Relationships and family', 'Conflict, distance, or setting limits'),
    (Icons.bedtime_outlined, 'Sleep and restlessness', 'Trouble falling asleep, or a mind that will not settle'),
    (Icons.cloud_outlined, 'Anxiety or low mood', 'Worry, sadness, or feeling flat'),
  ];

  static List<(String, String)> get _phqOptions => [
    (tr('Not at all'), '0'),
    (tr('Several days'), '+1'),
    (tr('More than half the days'), '+2'),
    (tr('Nearly every day'), '+3'),
  ];

  List<_Q> _questions(S s) => [
        _Q(
          tr('How have you been feeling lately?'),
          tr('There is no wrong answer here.'),
          [
            tr('Overwhelmed'),
            tr('A bit low'),
            tr('Okay'),
            tr('Mostly good'),
            tr('Really well'),
          ],
        ),
        _Q(
          tr('What kind of support are you looking for?'),
          tr('This sets the path we open first.'),
          [
            s.spiritualPsychiatry,
            s.psychiatry,
            s.cooking,
            tr('Not sure yet'),
          ],
        ),
        _Q(
          tr('How would you prefer to connect?'),
          tr('You can change this any time.'),
          [
            tr('Private video sessions'),
            tr('Journaling first'),
            tr('Community circles'),
            tr('A mix of all three'),
          ],
        ),
      ];

  String get _stepLabel => switch (_step) {
        0 => trx('Step 1 of $_totalSteps • What brings you here', 'ደረጃ 1 ከ$_totalSteps • ምን አመጣዎት'),
        1 => trx('Step 2 of $_totalSteps • How you feel', 'ደረጃ 2 ከ$_totalSteps • ስሜትዎ'),
        2 => trx('Step 3 of $_totalSteps • Your path', 'ደረጃ 3 ከ$_totalSteps • የሚፈልጉት ድጋፍ'),
        _ => trx('Step 4 of $_totalSteps • How to connect', 'ደረጃ 4 ከ$_totalSteps • የሚመርጡት አገናኝ'),
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
        'gender_preference': const ['none', 'female', 'male'][_genderPref],
        'languages': [for (final i in _languages) const ['en', 'am', 'om', 'ti'][i]],
        'approach': [for (final i in _modalities) i],
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
    final theme = Theme.of(context);
    final questions = _questions(s);
    final isLast = _step == _totalSteps - 1;

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: FriendStitchGlassHeader(
        title: tr('A few questions'),
        onBack: _back,
        onSos: () => context.push(AppRoutes.crisis),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FriendContentWidth(
            child: FriendStitchProgressTrack(step: _step, totalSteps: _totalSteps, stepLabel: _stepLabel),
          ),
          Expanded(
            child: FriendContentWidth(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 16, FriendLayout.horizontal, 32),
                children: [
                  if (_step == 0) ...[
                    Semantics(
                      header: true,
                      child: Text(tr('Help us find the right person.'), style: theme.textTheme.headlineMedium),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('Your answers help us suggest people who fit. Only you and the professional you book can see them.'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const FriendVaultBadge(),
                    const SizedBox(height: 28),
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
          ),
          FriendStitchStickyBar(
            onBack: _step > 0 ? _back : null,
            primaryLabel: isLast ? tr('Create Account') : s.continueLabel,
            primaryEnabled: _canContinue,
            onPrimary: _canContinue ? _continue : null,
          ),
        ],
      ),
    );
  }

  Widget _question(String title, {String? hint}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(hint, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _groupLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _buildConcernsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _question(tr('What brings you to Akilil today?'), hint: tr('Choose as many as you like.')),
        for (var i = 0; i < _concernItems.length; i++) ...[
          FriendIntentChip(
            icon: _concernItems[i].$1,
            title: tr(_concernItems[i].$2),
            subtitle: tr(_concernItems[i].$3),
            selected: _concerns.contains(i),
            onTap: () => setState(() {
              if (!_concerns.remove(i)) _concerns.add(i);
            }),
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
        _question(
          tr('Over the last 2 weeks, how often have you felt down, depressed, or hopeless?'),
          hint: q.hint,
        ),
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
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: FriendColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('This is a screening tool, not a diagnosis.'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModalityStep(_Q q) {
    final modalityLabels = [
      tr('Practical tools for thoughts (CBT)'),
      tr('Body and breathing'),
      tr('Talking it through in depth'),
      tr('Someone who just listens'),
    ];
    final genderLabels = [tr('No preference'), tr('A woman'), tr('A man')];
    final langLabels = [tr('English'), tr('Amharic'), tr('Afaan Oromoo'), tr('Tigrinya')];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _question(
          tr('Who would you like to talk to?'),
          hint: tr('Tell us what would make you most comfortable. You can change it later.'),
        ),
        _groupLabel(tr('How you like to work')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < modalityLabels.length; i++)
              FilterChip(
                label: Text(modalityLabels[i]),
                selected: _modalities.contains(i),
                onSelected: (_) => setState(() {
                  if (!_modalities.remove(i)) _modalities.add(i);
                }),
              ),
          ],
        ),
        _groupLabel(tr('I would prefer to talk to')),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < genderLabels.length; i++)
              ButtonSegment(value: i, label: Text(genderLabels[i], maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          selected: {_genderPref},
          onSelectionChanged: (v) => setState(() => _genderPref = v.first),
        ),
        _groupLabel(tr('Languages I speak')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < langLabels.length; i++)
              FilterChip(
                label: Text(langLabels[i]),
                selected: _languages.contains(i),
                onSelected: (_) => setState(() {
                  if (!_languages.remove(i)) _languages.add(i);
                }),
              ),
          ],
        ),
        _groupLabel(q.title),
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
        _question(q.title, hint: q.hint),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FriendPhqRadioOption(
              label: q.options[i],
              pointsLabel: '',
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
