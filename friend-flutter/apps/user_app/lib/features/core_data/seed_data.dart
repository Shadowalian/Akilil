/// Built-in self-help content that ships with the app: worksheets, the
/// PHQ-9 / GAD-7 questionnaires and daily journal prompts. Text is English
/// here and translated at render time through `tr()`.
library;

class SeedData {
  SeedData._();

  static final List<Map<String, dynamic>> worksheets = [
    {
      'id': 'ws-thought-record',
      'title': 'Thought record',
      'category': 'CBT Tools',
      'tag': 'Self-guided',
      'icon': 'edit_note_rounded',
      'is_completed': false,
      'description':
          'Identify automatic negative thoughts, test cognitive distortions, and construct balanced, objective counter-perspectives.',
      'fields': [
        {
          'id': 'situation',
          'label': 'What happened',
          'placeholder': 'What happened? Where were you? Who was involved?',
        },
        {
          'id': 'automatic_thought',
          'label': 'The first thought',
          'placeholder': 'What was the immediate sentence that entered your mind?',
        },
        {
          'id': 'distortion',
          'label': 'Thinking trap you noticed',
          'type': 'distortion_picker',
        },
        {
          'id': 'evidence_against',
          'label': 'Evidence against the thought',
          'placeholder': 'What facts contradict your catastrophic prediction?',
        },
        {
          'id': 'balanced_thought',
          'label': 'A more balanced view',
          'placeholder': 'What is a realistic, compassionate alternative view?',
        },
      ],
    },
    {
      'id': 'ws-decatastrophizing',
      'title': 'When you fear the worst',
      'category': 'Anxiety & Panic',
      'tag': 'Evidence-Based',
      'icon': 'psychology_alt_rounded',
      'is_completed': false,
      'description':
          'Walk through the absolute worst-case scenario, examine its true probability, and build an actionable contingency plan.',
      'fields': [
        {
          'id': 'worry',
          'label': 'What are you most worried will happen?',
          'placeholder': 'e.g. Giving the presentation tomorrow and freezing up.',
        },
        {
          'id': 'worst_case',
          'label': 'If the worst really happened, what would it look like?',
          'placeholder': 'Describe the scenario without self-censoring.',
        },
        {
          'id': 'probability',
          'label': 'Realistically, how likely is this worst case? (1-10)',
          'placeholder': 'e.g. 2 out of 10',
        },
        {
          'id': 'coping_plan',
          'label': 'How would you recover and handle it if it did happen?',
          'placeholder': 'I could pause, take a sip of water, look at my notes...',
        },
      ],
    },
    {
      'id': 'ws-box-breathing',
      'title': 'Box breathing',
      'category': 'Mindfulness',
      'tag': 'Interactive Tool',
      'icon': 'air_rounded',
      'is_completed': false,
      'is_interactive': true,
      'description':
          'A slow 4-count breathing rhythm that helps your body settle when you feel tense or panicky.',
    },
    {
      'id': 'ws-grounding-54321',
      'title': '5-4-3-2-1 grounding',
      'category': 'Anxiety & Panic',
      'tag': 'Somatic Tool',
      'icon': 'spa_rounded',
      'is_completed': false,
      'description':
          'Anchor your awareness in physical reality using sight, touch, sound, smell, and taste to defuse acute panic or dissociation.',
      'fields': [
        {
          'id': 'step5',
          'label': '5 Things You Can See',
        },
        {
          'id': 'step4',
          'label': '4 Things You Can Physically Touch',
        },
        {
          'id': 'step3',
          'label': '3 Things You Can Hear',
        },
        {
          'id': 'step2',
          'label': '2 Things You Can Smell',
        },
        {
          'id': 'step1',
          'label': '1 Thing You Can Taste',
        },
      ],
    },
    {
      'id': 'ws-boundaries',
      'title': 'Saying no, kindly and clearly',
      'category': 'Boundaries & Relationships',
      'tag': 'Communication',
      'icon': 'shield_outlined',
      'is_completed': false,
      'description':
          'Draft clear, respectful boundary declarations without over-explaining or apologizing for your emotional capacity.',
      'fields': [
        {
          'id': 'boundary_situation',
          'label': 'Where do you need a limit?',
          'placeholder': 'e.g. Taking weekend work requests from colleagues.',
        },
        {
          'id': 'boundary_script',
          'label': 'What I will say',
          'placeholder': '“I value our project, but I do not review emails on weekends. I will gladly review this first thing Monday.”',
        },
      ],
    },
    {
      'id': 'ws-gratitude',
      'title': 'Three good things',
      'category': 'Depression & Mood',
      'tag': 'Daily Habit',
      'icon': 'favorite_border_rounded',
      'is_completed': false,
      'description':
          'Counteract the brain’s evolutionary negativity bias by deliberately cataloging specific moments of safety, warmth, and grace.',
      'fields': [
        {
          'id': 'g1',
          'label': '1. A specific moment that brought peace today',
        },
        {
          'id': 'g2',
          'label': '2. Something I appreciate about my body or mind',
        },
        {
          'id': 'g3',
          'label': '3. An act of kindness I witnessed or received',
        },
      ],
    },
  ];

  static final Map<String, dynamic> assessments = {
    'phq9': {
      'title': 'PHQ-9 Depression Screener',
      'subtitle': 'Over the last 2 weeks, how often have you been bothered by:',
      'questions': [
        'Little interest or pleasure in doing things',
        'Feeling down, depressed, or hopeless',
        'Trouble falling or staying asleep, or sleeping too much',
        'Feeling tired or having little energy',
        'Poor appetite or overeating',
        'Feeling bad about yourself — or that you are a failure',
        'Trouble concentrating on things, such as reading or television',
        'Moving or speaking slowly, or being unusually fidgety/restless',
        'Thoughts that you would be better off dead, or of hurting yourself',
      ],
    },
    'gad7': {
      'title': 'GAD-7 Anxiety Screener',
      'subtitle': 'Over the last 2 weeks, how often have you been bothered by:',
      'questions': [
        'Feeling nervous, anxious, or on edge',
        'Not being able to stop or control worrying',
        'Worrying too much about different things',
        'Trouble relaxing',
        'Being so restless that it is hard to sit still',
        'Becoming easily annoyed or irritable',
        'Feeling afraid, as if something awful might happen',
      ],
    },
  };

  static final List<Map<String, String>> journalPrompts = [
    {
      'title': 'Challenging anxious predictions',
      'prompt': 'What catastrophic story is your mind telling you today? How can you look at it through the lens of kind curiosity rather than certainty?',
    },
    {
      'title': 'Honouring your limits',
      'prompt': 'What is one expectation you can take off your plate today to give your body space to breathe?',
    },
    {
      'title': 'A Letter from Your Future Self',
      'prompt': 'Imagine yourself one year from now, calm and steady. What gentle advice would they give you about this current storm?',
    },
    {
      'title': 'The smallest anchor',
      'prompt': 'Describe three micro-moments from the last 24 hours that felt gentle, quiet, or safe.',
    },
  ];
}
