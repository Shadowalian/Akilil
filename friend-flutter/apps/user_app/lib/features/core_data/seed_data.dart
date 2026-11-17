/// BetterHelp-grade Clinical Seed & Fallback Engine
/// Guarantees ZERO empty states across all screens:
/// Licensed Therapists, Assigned Counselor Messaging, Live Sessions,
/// CBT Worksheets, Groupinars, Clinical Assessments, Crisis Resources,
/// Community Circles, Goals, Habits, and Notifications.
library;

class SeedData {
  SeedData._();

  // ─── 1. Featured Licensed Therapists ─────────────────────────────────────────

  static final List<Map<String, dynamic>> professionals = [
    {
      'id': 'pro-maya-lin',
      'name': 'Dr. Maya Lin, Psy.D.',
      'title': 'Licensed Clinical Psychologist & CBT Specialist',
      'category': 'psychiatry',
      'rating_avg': 4.96,
      'rating_count': 382,
      'hourly_rate_cents': 6500,
      'currency': 'USD',
      'languages': ['English', 'Mandarin'],
      'specialties': [
        'Anxiety & Panic',
        'CBT Therapy',
        'Depression',
        'Burnout & Stress',
        'Mindfulness',
      ],
      'license': 'CA Licensed Psychologist #PSY29841',
      'education': 'Stanford University (Psy.D.), UC Berkeley (B.A.)',
      'experience_years': 12,
      'match_score': 98,
      'badge': 'Primary Matched Counselor',
      'is_primary': true,
      'bio':
          'Dr. Maya Lin has over a decade of clinical experience guiding individuals through severe anxiety, acute burnout, panic disorder, and major life transitions. Her approach integrates evidence-based Cognitive Behavioral Therapy (CBT) with somatic mindfulness tools.',
      'approach':
          'Cognitive Behavioral Therapy (CBT), Mindfulness-Based Cognitive Therapy (MBCT), Acceptance & Commitment Therapy (ACT)',
      'available_slots': [
        {'id': 'slot-1', 'time': 'Today, 3:00 PM', 'available': true},
        {'id': 'slot-2', 'time': 'Today, 5:30 PM', 'available': true},
        {'id': 'slot-3', 'time': 'Tomorrow, 10:00 AM', 'available': true},
        {'id': 'slot-4', 'time': 'Tomorrow, 2:00 PM', 'available': true},
      ],
    },
    {
      'id': 'pro-marcus-vance',
      'name': 'Marcus Vance, LCSW',
      'title': 'Trauma Recovery & Grief Counselor',
      'category': 'psychiatry',
      'rating_avg': 4.88,
      'rating_count': 245,
      'hourly_rate_cents': 6000,
      'currency': 'USD',
      'languages': ['English', 'Spanish'],
      'specialties': [
        'Trauma & PTSD',
        'Grief & Bereavement',
        'EMDR',
        'Emotional Regulation',
      ],
      'license': 'NY Licensed Clinical Social Worker #089421',
      'education': 'Columbia University (MSW)',
      'experience_years': 10,
      'match_score': 95,
      'badge': 'Trauma Specialist',
      'is_primary': false,
      'bio':
          'Marcus specializes in trauma-informed care and grief processing. He provides a safe, grounded space to unpack deep emotional burdens and restore personal resilience.',
      'approach': 'EMDR Certified, Somatic Experiencing, Narrative Therapy',
      'available_slots': [
        {'id': 'slot-5', 'time': 'Tomorrow, 11:30 AM', 'available': true},
        {'id': 'slot-6', 'time': 'Wednesday, 4:00 PM', 'available': true},
      ],
    },
    {
      'id': 'pro-elena-rostova',
      'name': 'Dr. Elena Rostova, MD',
      'title': 'Integrative Psychiatrist & Sleep Specialist',
      'category': 'psychiatry',
      'rating_avg': 4.94,
      'rating_count': 412,
      'hourly_rate_cents': 9000,
      'currency': 'USD',
      'languages': ['English', 'Russian'],
      'specialties': [
        'Sleep & Insomnia',
        'ADHD Management',
        'Mood Disorders',
        'Integrative Psychiatry',
      ],
      'license': 'WA Medical License #MD60893321',
      'education': 'Johns Hopkins School of Medicine (MD)',
      'experience_years': 16,
      'match_score': 93,
      'badge': 'Board Certified MD',
      'is_primary': false,
      'bio':
          'Dr. Elena Rostova approaches mental wellness through the lens of nervous system regulation, circadian health, and evidence-based psychotherapy.',
      'approach':
          'Integrative Psychiatry, CBT-I (Insomnia), Nutritional Neuroscience',
      'available_slots': [
        {'id': 'slot-7', 'time': 'Thursday, 1:00 PM', 'available': true},
        {'id': 'slot-8', 'time': 'Friday, 9:00 AM', 'available': true},
      ],
    },
    {
      'id': 'pro-sofia-chen',
      'name': 'Sofia Chen, LMFT',
      'title': 'Couples & Family Dynamics Counselor',
      'category': 'spiritual_psychiatry',
      'rating_avg': 4.92,
      'rating_count': 198,
      'hourly_rate_cents': 6500,
      'currency': 'USD',
      'languages': ['English', 'Mandarin'],
      'specialties': [
        'Couples Counseling',
        'Healthy Boundaries',
        'Attachment Repair',
        'Conflict Resolution',
      ],
      'license': 'CA Licensed Marriage & Family Therapist #MFC112984',
      'education': 'UCLA (M.A. Clinical Psychology)',
      'experience_years': 9,
      'match_score': 96,
      'badge': 'Relationship Expert',
      'is_primary': false,
      'bio':
          'Sofia helps partners and individuals deconstruct reactive patterns and build secure, empathetic connection using Emotionally Focused Therapy.',
      'approach': 'Emotionally Focused Therapy (EFT), Gottman Method Level 3',
      'available_slots': [
        {'id': 'slot-9', 'time': 'Tomorrow, 3:00 PM', 'available': true},
      ],
    },
    {
      'id': 'pro-david-oconnor',
      'name': 'David O’Connor, LPC',
      'title': 'Spiritual Psychology & Life Purpose Counselor',
      'category': 'spiritual_psychiatry',
      'rating_avg': 4.87,
      'rating_count': 164,
      'hourly_rate_cents': 5500,
      'currency': 'USD',
      'languages': ['English'],
      'specialties': [
        'Spiritual Direction',
        'Existential Therapy',
        'Meaning & Purpose',
        'Grief & Transitions',
      ],
      'license': 'TX Licensed Professional Counselor #74819',
      'education': 'Duke Divinity School (M.Div.), Boston College (M.A.)',
      'experience_years': 14,
      'match_score': 91,
      'badge': 'Spiritual Integration',
      'is_primary': false,
      'bio':
          'David blends classical existential philosophy and compassionate spiritual direction to help clients rediscover deep purpose during life transitions.',
      'approach':
          'Logotherapy, Contemplative Presence, Narrative Deconstruction',
      'available_slots': [
        {'id': 'slot-10', 'time': 'Friday, 11:00 AM', 'available': true},
      ],
    },
    {
      'id': 'pro-amara-okafor',
      'name': 'Amara Okafor, Psy.D.',
      'title': 'Multicultural Mental Health & Self-Worth',
      'category': 'psychiatry',
      'rating_avg': 4.95,
      'rating_count': 310,
      'hourly_rate_cents': 6500,
      'currency': 'USD',
      'languages': ['English', 'Igbo'],
      'specialties': [
        'Identity & Belonging',
        'Imposter Syndrome',
        'Self-Worth',
        'High Achiever Anxiety',
      ],
      'license': 'IL Licensed Psychologist #07100984',
      'education': 'Northwestern University (Psy.D.)',
      'experience_years': 11,
      'match_score': 94,
      'badge': 'Diversity & Inclusion Leader',
      'is_primary': false,
      'bio':
          'Dr. Amara specializes in helping first-generation professionals and high achievers untangle self-worth from productivity and overcome internal friction.',
      'approach': 'Psychodynamic, Relational Cultural Theory, Compassion-Focused',
      'available_slots': [
        {'id': 'slot-11', 'time': 'Wednesday, 2:30 PM', 'available': true},
      ],
    },
    {
      'id': 'pro-noah-wright',
      'name': 'Chef Noah Wright',
      'title': 'Culinary Therapy & Mindful Nourishment',
      'category': 'cooking',
      'rating_avg': 4.82,
      'rating_count': 135,
      'hourly_rate_cents': 4500,
      'currency': 'USD',
      'languages': ['English', 'French'],
      'specialties': [
        'Sensory Grounding Cooking',
        'Gut-Brain Axis Nutrition',
        'Mindful Eating',
        'Kitchen Meditation',
      ],
      'license': 'Certified Culinary Medicine Specialist (CCMS)',
      'education': 'Le Cordon Bleu Paris & Culinary Institute of America',
      'experience_years': 8,
      'match_score': 89,
      'badge': 'Culinary Wellness',
      'is_primary': false,
      'bio':
          'Chef Noah uses the sensory art of slow cooking to quiet racing thoughts and re-establish a compassionate relationship with nourishment.',
      'approach':
          'Sensory Activation, Mindful Slow Food, Nutritional Psychology',
      'available_slots': [
        {'id': 'slot-12', 'time': 'Saturday, 11:00 AM', 'available': true},
      ],
    },
  ];

  // ─── 2. Dedicated Primary Therapist Conversation ─────────────────────────────

  static final Map<String, dynamic> primaryTherapist = professionals.first;

  static final List<Map<String, dynamic>> conversationMessages = [
    {
      'id': 'msg-1',
      'sender': 'therapist',
      'sender_name': 'Dr. Maya Lin, Psy.D.',
      'body':
          'Welcome to your private counseling room! I have reviewed your intake questionnaire regarding your anxiety patterns and sleep difficulties. You took a courageous step reaching out.',
      'time': 'Yesterday, 10:14 AM',
      'type': 'text',
    },
    {
      'id': 'msg-2',
      'sender': 'therapist',
      'sender_name': 'Dr. Maya Lin, Psy.D.',
      'body':
          'I just assigned you a digital CBT Thought Record. Whenever you notice a surge of anxiety or a catastrophic thought, open it and write down the automatic sentence. We will review it in our upcoming video call.',
      'time': 'Yesterday, 10:15 AM',
      'type': 'worksheet_assignment',
      'worksheet_id': 'ws-thought-record',
      'worksheet_title': 'CBT Thought Record',
    },
    {
      'id': 'msg-3',
      'sender': 'user',
      'sender_name': 'You',
      'body':
          'Thank you Dr. Lin. I really appreciate having a place where I can send thoughts whenever things feel overwhelming. I will work on the worksheet tonight.',
      'time': 'Yesterday, 2:40 PM',
      'type': 'text',
    },
    {
      'id': 'msg-4',
      'sender': 'therapist',
      'sender_name': 'Dr. Maya Lin, Psy.D.',
      'body':
          'Here is a quick 1-minute voice note on how to use grounding when you feel tension in your chest.',
      'time': 'Today, 9:20 AM',
      'type': 'voice_note',
      'duration': '1:14',
    },
    {
      'id': 'msg-5',
      'sender': 'therapist',
      'sender_name': 'Dr. Maya Lin, Psy.D.',
      'body':
          'Our next live video session is scheduled for today at 3:00 PM. Looking forward to connecting face-to-face!',
      'time': 'Today, 9:22 AM',
      'type': 'text',
    },
  ];

  // ─── 3. Upcoming & Past Appointments ─────────────────────────────────────────

  static final List<Map<String, dynamic>> appointments = [
    {
      'id': 'appt-live-today',
      'scheduled_at': DateTime.now()
          .add(const Duration(minutes: 25))
          .toIso8601String(),
      'duration_minutes': 50,
      'status': 'confirmed',
      'kind': 'video',
      'price_cents': 6500,
      'professional': primaryTherapist,
      'room_url': 'https://meet.jit.si/friend-session-mayalin-user1',
      'topics': ['CBT Cognitive Restructuring', 'Anxiety De-escalation', 'Sleep Hygiene'],
      'notes': 'Please have your CBT thought record handy.',
    },
    {
      'id': 'appt-next-week',
      'scheduled_at': DateTime.now()
          .add(const Duration(days: 4, hours: 2))
          .toIso8601String(),
      'duration_minutes': 50,
      'status': 'confirmed',
      'kind': 'video',
      'price_cents': 6500,
      'professional': primaryTherapist,
      'room_url': 'https://meet.jit.si/friend-session-mayalin-user2',
      'topics': ['Progress Review', 'Boundary Setting'],
      'notes': 'Check-in on homework and weekly mood score.',
    },
    {
      'id': 'appt-past-1',
      'scheduled_at': DateTime.now()
          .subtract(const Duration(days: 6, hours: 3))
          .toIso8601String(),
      'duration_minutes': 50,
      'status': 'completed',
      'kind': 'video',
      'price_cents': 6500,
      'professional': primaryTherapist,
      'summary_notes':
          'Client explored root triggers of workplace anxiety. Agreed to practice 5-4-3-2-1 grounding daily and maintain the CBT Thought Record.',
    },
  ];

  // ─── 4. Clinical Therapy Worksheets & Exercises ───────────────────────────────

  static final List<Map<String, dynamic>> worksheets = [
    {
      'id': 'ws-thought-record',
      'title': 'CBT Thought Record',
      'category': 'CBT Tools',
      'tag': 'Self-guided',
      'icon': 'edit_note_rounded',
      'is_completed': false,
      'description':
          'Identify automatic negative thoughts, test cognitive distortions, and construct balanced, objective counter-perspectives.',
      'fields': [
        {
          'id': 'situation',
          'label': 'Situation / Trigger',
          'placeholder': 'What happened? Where were you? Who was involved?',
        },
        {
          'id': 'automatic_thought',
          'label': 'Automatic Thought',
          'placeholder': 'What was the immediate sentence that entered your mind?',
        },
        {
          'id': 'distortion',
          'label': 'Cognitive Distortion Identified',
          'type': 'distortion_picker',
        },
        {
          'id': 'evidence_against',
          'label': 'Evidence Against the Thought',
          'placeholder': 'What facts contradict your catastrophic prediction?',
        },
        {
          'id': 'balanced_thought',
          'label': 'Balanced / Rational Perspective',
          'placeholder': 'What is a realistic, compassionate alternative view?',
        },
      ],
    },
    {
      'id': 'ws-decatastrophizing',
      'title': 'Anxiety Decatastrophizer',
      'category': 'Anxiety & Panic',
      'tag': 'Evidence-Based',
      'icon': 'psychology_alt_rounded',
      'is_completed': false,
      'description':
          'Walk through the absolute worst-case scenario, examine its true probability, and build an actionable contingency plan.',
      'fields': [
        {
          'id': 'worry',
          'label': 'What is your core catastrophic worry?',
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
      'title': 'Interactive Box Breathing',
      'category': 'Mindfulness',
      'tag': 'Interactive Tool',
      'icon': 'air_rounded',
      'is_completed': false,
      'is_interactive': true,
      'description':
          '4-second rhythmic breathing cycle used by therapists and Navy SEALs to rapidly regulate parasympathetic nervous system response.',
    },
    {
      'id': 'ws-grounding-54321',
      'title': '5-4-3-2-1 Sensory Grounding',
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
      'title': 'Boundary Script & Assertiveness Plan',
      'category': 'Boundaries & Relationships',
      'tag': 'Communication',
      'icon': 'shield_outlined',
      'is_completed': false,
      'description':
          'Draft clear, respectful boundary declarations without over-explaining or apologizing for your emotional capacity.',
      'fields': [
        {
          'id': 'boundary_situation',
          'label': 'Where is a boundary needed?',
          'placeholder': 'e.g. Taking weekend work requests from colleagues.',
        },
        {
          'id': 'boundary_script',
          'label': 'My Assertive Statement Script',
          'placeholder': '“I value our project, but I do not review emails on weekends. I will gladly review this first thing Monday.”',
        },
      ],
    },
    {
      'id': 'ws-gratitude',
      'title': 'Daily Gratitude & Positivity Log',
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

  // ─── 5. Groupinars / Therapist-Led Group Sessions ───────────────────────────

  static final List<Map<String, dynamic>> groups = [
    {
      'id': 'grp-anxiety-circle',
      'title': 'Mastering Anxiety & Panic Triggers',
      'host_name': 'Dr. Maya Lin, Psy.D.',
      'host_role': 'Licensed Clinical Psychologist',
      'schedule': 'Every Tuesday, 6:00 PM EST',
      'next_session': 'Today, 6:00 PM EST',
      'attendees_count': 48,
      'is_registered': true,
      'is_live': false,
      'category': 'Anxiety',
      'description':
          'A weekly clinician-moderated interactive groupinar covering somatic down-regulation, cognitive reframing, and shared support.',
    },
    {
      'id': 'grp-mindfulness-somatic',
      'title': 'Mindfulness & Somatic Grounding Circle',
      'host_name': 'Dr. Elena Rostova, MD',
      'host_role': 'Integrative Psychiatrist',
      'schedule': 'Every Thursday, 7:00 PM EST',
      'next_session': 'Thursday, 7:00 PM EST',
      'attendees_count': 62,
      'is_registered': false,
      'is_live': false,
      'category': 'Mindfulness',
      'description':
          'Experiential guided nervous system release, breathwork cycles, and restorative somatic practices.',
    },
    {
      'id': 'grp-relationships-boundaries',
      'title': 'Navigating Relationship Boundaries',
      'host_name': 'Sofia Chen, LMFT',
      'host_role': 'Couples & Family Therapist',
      'schedule': 'Every Wednesday, 5:00 PM EST',
      'next_session': 'Tomorrow, 5:00 PM EST',
      'attendees_count': 54,
      'is_registered': true,
      'is_live': false,
      'category': 'Relationships',
      'description':
          'Learn to communicate difficult boundaries with partners, parents, and friends without guilt or emotional recoil.',
    },
    {
      'id': 'grp-grief-healing',
      'title': 'Safe Harbor: Grief & Loss Support',
      'host_name': 'Marcus Vance, LCSW',
      'host_role': 'Trauma & Bereavement Specialist',
      'schedule': 'Every Saturday, 11:00 AM EST',
      'next_session': 'Saturday, 11:00 AM EST',
      'attendees_count': 29,
      'is_registered': false,
      'is_live': false,
      'category': 'Grief',
      'description':
          'A gentle, non-judgmental space for anyone navigating the deep waves of bereavement, divorce, or significant life change.',
    },
    {
      'id': 'grp-adhd-procrastination',
      'title': 'Overcoming Executive Dysfunction & ADHD',
      'host_name': 'Dr. Amara Okafor, Psy.D.',
      'host_role': 'Clinical Neuropsychology',
      'schedule': 'Every Monday, 4:00 PM EST',
      'next_session': 'Monday, 4:00 PM EST',
      'attendees_count': 78,
      'is_registered': false,
      'is_live': false,
      'category': 'ADHD & Focus',
      'description':
          'Practical dopamine scaffolding, body doubling routines, and shame-free behavioral habit construction.',
    },
  ];

  // ─── 6. Clinical Assessments (PHQ-9 & GAD-7) ─────────────────────────────────

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

  // ─── 7. Emergency & Crisis Safety Resources ──────────────────────────────────

  static final List<Map<String, dynamic>> crisisResources = [
    {
      'name': '988 Suicide & Crisis Lifeline',
      'desc': 'Free, confidential support available 24/7 in English & Spanish.',
      'action_type': 'call',
      'action_target': '988',
      'badge': '24/7 Lifeline',
      'icon': 'phone_in_talk_rounded',
    },
    {
      'name': 'Crisis Text Line',
      'desc': 'Free 24/7 text support with a trained crisis counselor.',
      'action_type': 'sms',
      'action_target': '741741',
      'body': 'HOME',
      'badge': 'Text HOME',
      'icon': 'chat_bubble_outline_rounded',
    },
    {
      'name': 'The Trevor Project (LGBTQ+ Crisis)',
      'desc': '24/7 confidential suicide prevention & crisis counseling for LGBTQ youth.',
      'action_type': 'call',
      'action_target': '1-866-488-7386',
      'badge': 'LGBTQ+ Affirming',
      'icon': 'favorite_rounded',
    },
    {
      'name': 'Veterans Crisis Line',
      'desc': 'Dial 988 and press 1, or text 838255 for confidential veteran support.',
      'action_type': 'call',
      'action_target': '988',
      'badge': 'Veterans',
      'icon': 'shield_rounded',
    },
    {
      'name': 'International Emergency Directory',
      'desc': 'Find verified local crisis hotlines in over 120 countries worldwide.',
      'action_type': 'url',
      'action_target': 'https://findahelpline.com',
      'badge': 'Global',
      'icon': 'public_rounded',
    },
  ];

  static final Map<String, dynamic> safetyPlan = {
    'warning_signs': [
      'Isolating from family and ignoring phone calls for 3+ days',
      'Feeling an overwhelming tightness in the chest and racing heart',
      'Skipping meals and staying awake past 3:00 AM',
    ],
    'internal_coping': [
      '10-minute Box Breathing in a quiet, darkened room',
      'Stepping outside for a brisk 15-minute walk without phone',
      'Listening to the 432Hz ambient sleep frequencies playlist',
    ],
    'trusted_people': [
      {'name': 'Sarah (Sister)', 'phone': '555-019-2831'},
      {'name': 'Alex (Best Friend)', 'phone': '555-014-9923'},
    ],
    'safe_environment': [
      'Keep bedroom clutter-free and dim warm lighting in the evening',
      'Turn off news feeds and notifications after 8:00 PM',
    ],
  };

  // ─── 8. In-App Notifications Center ──────────────────────────────────────────

  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 'notif-1',
      'title': 'Session starting in 25 minutes',
      'body': 'Your live video call with Dr. Maya Lin begins at 3:00 PM. Tap to prepare your room.',
      'time': 'Just now',
      'type': 'session',
      'is_read': false,
      'route': '/appointments',
    },
    {
      'id': 'notif-2',
      'title': 'Dr. Maya Lin sent a message',
      'body': '“Here is a quick voice note on grounding when you feel tension...”',
      'time': '2 hours ago',
      'type': 'message',
      'is_read': false,
      'route': '/messages',
    },
    {
      'id': 'notif-3',
      'title': 'Worksheet Assigned: CBT Thought Record',
      'body': 'Dr. Lin assigned you a new thought restructuring exercise.',
      'time': 'Yesterday',
      'type': 'worksheet',
      'is_read': true,
      'route': '/worksheets',
    },
    {
      'id': 'notif-4',
      'title': '7-Day Mindful Streak Achieved! 🎉',
      'body': 'You have completed your daily check-in 7 days in a row. Your nervous system thanks you.',
      'time': 'Yesterday',
      'type': 'achievement',
      'is_read': true,
      'route': '/today',
    },
    {
      'id': 'notif-5',
      'title': 'Anxiety Circle Meeting tonight',
      'body': '“Mastering Anxiety Triggers” goes live at 6:00 PM EST with Dr. Maya Lin.',
      'time': '3 days ago',
      'type': 'group',
      'is_read': true,
      'route': '/groups',
    },
  ];

  // ─── 9. BetterHelp Subscription & Plan Tiers ─────────────────────────────────

  static final List<Map<String, dynamic>> subscriptionPlans = [
    {
      'id': 'plan-weekly',
      'name': 'Weekly Therapy Plan',
      'price_display': '\$65 / week',
      'price_cents': 6500,
      'cadence': 'Billed monthly (\$260)',
      'is_popular': true,
      'features': [
        '1 live 50-min video/audio session per week',
        '24/7 unlimited messaging with your dedicated counselor',
        'Full CBT Digital Worksheets & interactive exercises',
        'Access to all weekly Groupinars & clinician circles',
        'Switch therapists at any time at zero extra cost',
      ],
    },
    {
      'id': 'plan-intensive',
      'name': 'Comprehensive Care Plan',
      'price_display': '\$85 / week',
      'price_cents': 8500,
      'cadence': 'Billed monthly (\$340)',
      'is_popular': false,
      'features': [
        '2 live 50-min video/audio sessions per week',
        'Priority same-day counselor response guarantee',
        'Unlimited messaging & voice note audio attachments',
        'Complete clinical worksheets & symptom tracking reports',
        'Dedicated emergency safety plan co-created with therapist',
      ],
    },
    {
      'id': 'plan-student',
      'name': 'Financial Assistance / Student Plan',
      'price_display': '\$45 / week',
      'price_cents': 4500,
      'cadence': 'Income-verified sliding scale',
      'is_popular': false,
      'features': [
        '1 live video/audio session every 2 weeks',
        'Continuous 24/7 chat with licensed therapist',
        'Access to full guided journal, CBT tools, & circles',
      ],
    },
  ];

  // ─── 10. Community Circles & Active Posts ─────────────────────────────────────

  static final List<Map<String, dynamic>> communityChannels = [
    {
      'id': 'chan-anxiety',
      'name': 'Anxiety & Overwhelm',
      'description': 'Safe ground to unmask panic, hypervigilance, and find calm together.',
      'member_count': 1420,
      'is_private': false,
      'posts': [
        {
          'id': 'post-1',
          'author': 'Clara M.',
          'author_initials': 'C',
          'time': '2 hours ago',
          'title': 'The physical symptoms of anxiety are so exhausting',
          'body':
              'Does anyone else get severe muscle tension in their upper back and jaw? My therapist suggested progressive muscle relaxation today and for the first time in weeks I felt my shoulders drop.',
          'likes': 38,
          'comments_count': 14,
        },
        {
          'id': 'post-2',
          'author': 'Julian R.',
          'author_initials': 'J',
          'time': '5 hours ago',
          'title': 'Small win: didn’t cancel plans because of anxiety',
          'body':
              'Almost turned my car around 3 times, but I used the 5-4-3-2-1 technique in the parking lot and ended up having a lovely dinner with old friends.',
          'likes': 82,
          'comments_count': 23,
        },
      ],
    },
    {
      'id': 'chan-mindful',
      'name': 'Mindful Living & Peace',
      'description': 'Daily gratitude, somatic grounding, and gentle presence practices.',
      'member_count': 980,
      'is_private': false,
    },
    {
      'id': 'chan-boundaries',
      'name': 'Healthy Boundaries & Self-Love',
      'description': 'Learning that saying "no" to others can be saying "yes" to our mental health.',
      'member_count': 1210,
      'is_private': false,
    },
    {
      'id': 'chan-healing',
      'name': 'Grief, Healing & Heartache',
      'description': 'Compassionate space where grief does not have to be hidden or rushed.',
      'member_count': 740,
      'is_private': false,
    },
  ];

  // ─── 11. Guided Journal Prompts & Seed Entries ───────────────────────────────

  static final List<Map<String, String>> journalPrompts = [
    {
      'title': 'Challenging Anxious Predictions',
      'prompt': 'What catastrophic story is your mind telling you today? How can you look at it through the lens of kind curiosity rather than certainty?',
    },
    {
      'title': 'Honoring Your Capacity',
      'prompt': 'What is one expectation you can take off your plate today to give your body space to breathe?',
    },
    {
      'title': 'A Letter from Your Future Self',
      'prompt': 'Imagine yourself one year from now, calm and steady. What gentle advice would they give you about this current storm?',
    },
    {
      'title': 'The Smallest Anchor',
      'prompt': 'Describe three micro-moments from the last 24 hours that felt gentle, quiet, or safe.',
    },
  ];

  static final List<Map<String, dynamic>> journalEntries = [
    {
      'id': 'entry-1',
      'title': 'Learning to pause before reacting',
      'content':
          'Today felt heavier in the afternoon. When the project deadline shifted, my immediate impulse was panic and overworking through the night. Instead, I opened the CBT thought record Dr. Maya assigned me, wrote out the catastrophic thoughts, and realized 90% of my panic was based on assumptions. Stepped away, had tea, and resumed with clarity.',
      'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
      'shared_with_therapist': true,
      'mood_score': 7,
    },
    {
      'id': 'entry-2',
      'title': 'Morning stillness by the window',
      'content':
          'Practiced the 4-second box breathing for 10 minutes before touching any email or phone notifications. The difference in my baseline heart rate is night and day.',
      'created_at': DateTime.now().subtract(const Duration(days: 3, hours: 2)).toIso8601String(),
      'shared_with_therapist': false,
      'mood_score': 8,
    },
  ];

  // ─── 12. Active Goals & Daily Habits ─────────────────────────────────────────

  static final List<Map<String, dynamic>> habits = [
    {
      'id': 'habit-1',
      'title': '10-minute Morning Box Breathing',
      'streak': 7,
      'completed_today': true,
      'category': 'Mindfulness',
    },
    {
      'id': 'habit-2',
      'title': 'Evening CBT Thought Restructuring',
      'streak': 5,
      'completed_today': true,
      'category': 'Therapy Tool',
    },
    {
      'id': 'habit-3',
      'title': '30-minute Outdoor Walk without Screen',
      'streak': 4,
      'completed_today': false,
      'category': 'Nervous System',
    },
    {
      'id': 'habit-4',
      'title': 'Log Daily Mood & Emotion Check-in',
      'streak': 12,
      'completed_today': true,
      'category': 'Self-Awareness',
    },
  ];

  static final List<Map<String, dynamic>> goals = [
    {
      'id': 'goal-1',
      'title': 'Reduce Acute Panic Response to Work Emails',
      'progress': 0.75,
      'target': '3 weeks of balanced CBT thought logging',
      'is_co_signed': true,
      'therapist_name': 'Dr. Maya Lin, Psy.D.',
    },
    {
      'id': 'goal-2',
      'title': 'Establish Sleep Hygiene & 11:00 PM Screen Cutoff',
      'progress': 0.60,
      'target': '5 days / week',
      'is_co_signed': true,
      'therapist_name': 'Dr. Maya Lin, Psy.D.',
    },
    {
      'id': 'goal-3',
      'title': 'Practice Direct Boundary Communication without Apology',
      'progress': 0.40,
      'target': 'Use boundary script in 3 personal situations',
      'is_co_signed': false,
    },
  ];

  // ─── 13. Anonymous Vents ─────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> vents = [
    {
      'id': 'vent-1',
      'content':
          'I feel so drained pretending that everything is completely under control when on the inside I am barely holding the pieces together. It feels so good to type this without having to smile.',
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'tag': 'Overwhelmed',
    },
    {
      'id': 'vent-2',
      'content':
          'Just needed to release the frustration of today. Not looking for advice or fixing. Just putting it down here and letting it go.',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'tag': 'Letting Go',
    },
  ];
}
