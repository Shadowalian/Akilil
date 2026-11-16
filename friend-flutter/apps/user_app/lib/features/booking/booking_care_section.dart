import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What the person booking chose about *who* the session is for and, for a
/// chef, *what* they will cook. Sent with `POST /appointments`.
@immutable
class BookingCareSelection {
  const BookingCareSelection({
    this.format = 'individual',
    this.dependentId,
    this.participants = const [],
    this.recipeId,
    this.priceCents,
    this.problem,
  });

  final String format;
  final int? dependentId;
  final List<({String name, String email})> participants;
  final int? recipeId;

  /// Price for the chosen format, when the professional's profile gave one.
  final int? priceCents;

  /// Why this selection can't be booked yet (shown under the section), or null.
  final String? problem;

  bool get isValid => problem == null;

  Map<String, dynamic> toPayload() => {
        'care_format': format,
        if (dependentId != null) 'dependent_id': dependentId,
        if (participants.isNotEmpty)
          'participants': [
            for (final p in participants)
              {'name': p.name, if (p.email.isNotEmpty) 'email': p.email},
          ],
        if (recipeId != null) 'recipe_id': recipeId,
      };
}

/// "Who is this for?" + (for chefs) "What will you cook?".
///
/// Reads what the professional offers from their profile payload and only
/// shows the options that can actually be booked.
class BookingCareSection extends ConsumerStatefulWidget {
  const BookingCareSection({
    super.key,
    required this.professional,
    required this.onChanged,
  });

  /// The `GET /professionals/{id}` payload.
  final Map<String, dynamic> professional;
  final ValueChanged<BookingCareSelection> onChanged;

  @override
  ConsumerState<BookingCareSection> createState() => _BookingCareSectionState();
}

class _BookingCareSectionState extends ConsumerState<BookingCareSection> {
  String _format = 'individual';
  int? _dependentId;
  int? _recipeId;
  final _partnerName = TextEditingController();
  final _partnerEmail = TextEditingController();
  final List<({TextEditingController name, TextEditingController email})> _family = [];

  List<Map<String, dynamic>> _dependents = const [];
  List<Map<String, dynamic>> _recipes = const [];
  bool _loading = true;

  Map<String, dynamic> get _pro => widget.professional;
  List<String> get _formats =>
      ((_pro['care_formats'] as List?) ?? const ['individual']).map((e) => e.toString()).toList();
  List<String> get _ageGroups =>
      ((_pro['age_groups'] as List?) ?? const ['adults']).map((e) => e.toString()).toList();
  bool get _requiresRecipe => _pro['requires_recipe'] == true;
  bool get _offersMinors => _formats.contains('child') || _formats.contains('teen');

  @override
  void initState() {
    super.initState();
    if (!_formats.contains('individual') && _formats.isNotEmpty) {
      _format = _offersMinors ? 'minor' : _formats.first;
    }
    _partnerName.addListener(_emit);
    _partnerEmail.addListener(_emit);
    _load();
  }

  @override
  void dispose() {
    _partnerName.dispose();
    _partnerEmail.dispose();
    for (final m in _family) {
      m.name.dispose();
      m.email.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    try {
      if (_offersMinors || _formats.contains('family')) {
        final res = await dio.get<Map<String, dynamic>>('/dependents');
        _dependents = ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      }
      if (_requiresRecipe) {
        final res = await dio.get<Map<String, dynamic>>(
          '/recipes',
          queryParameters: {'professional_user_id': _pro['user_id']},
        );
        _recipes = ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
        if (_recipes.length == 1) _recipeId = (_recipes.first['id'] as num).toInt();
      }
    } catch (_) {
      // Leave the lists empty; the section explains what is missing.
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _emit();
  }

  Map<String, dynamic>? get _dependent {
    for (final d in _dependents) {
      if ((d['id'] as num).toInt() == _dependentId) return d;
    }
    return null;
  }

  bool _servesDependent(Map<String, dynamic> d) => _ageGroups.contains(d['age_group']);

  /// The API format for the current choice ("minor" resolves by the child's age).
  String get _apiFormat {
    if (_format != 'minor') return _format;
    return _dependent?['age_group'] == 'teens' ? 'teen' : 'child';
  }

  int? get _price {
    final base = (_pro['hourly_rate_cents'] as num?)?.toInt();
    return switch (_apiFormat) {
      'couples' => (_pro['couples_rate_cents'] as num?)?.toInt() ?? base,
      'family' => (_pro['family_rate_cents'] as num?)?.toInt() ?? base,
      _ => base,
    };
  }

  String? get _problem {
    if (_loading) return 'Loading…';
    if (_format == 'minor' && _dependent == null) return 'Choose which child this session is for.';
    if (_format == 'couples' && _partnerName.text.trim().length < 2) return "Add your partner's name.";
    if (_format == 'couples' && _partnerEmail.text.trim().isNotEmpty && !_partnerEmail.text.contains('@')) {
      return "Check your partner's email address.";
    }
    if (_requiresRecipe && _recipes.isEmpty) return 'This chef has not published a recipe yet.';
    if (_requiresRecipe && _recipeId == null) return 'Choose what you will cook.';
    return null;
  }

  void _emit() {
    final participants = <({String name, String email})>[
      if (_format == 'couples' && _partnerName.text.trim().isNotEmpty)
        (name: _partnerName.text.trim(), email: _partnerEmail.text.trim()),
      if (_format == 'family')
        for (final m in _family)
          if (m.name.text.trim().length >= 2) (name: m.name.text.trim(), email: m.email.text.trim()),
    ];
    widget.onChanged(BookingCareSelection(
      format: _apiFormat,
      dependentId: (_format == 'minor' || _format == 'family') ? _dependentId : null,
      participants: participants,
      recipeId: _requiresRecipe ? _recipeId : null,
      priceCents: _price,
      problem: _problem,
    ));
    if (mounted) setState(() {});
  }

  void _pick(String format) {
    setState(() {
      _format = format;
      if (format != 'minor' && format != 'family') _dependentId = null;
    });
    _emit();
  }

  void _addFamilyMember() {
    if (_family.length >= 5) return;
    final row = (name: TextEditingController(), email: TextEditingController());
    row.name.addListener(_emit);
    row.email.addListener(_emit);
    setState(() => _family.add(row));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <({String key, String label, IconData icon})>[
      if (_formats.contains('individual')) (key: 'individual', label: 'Just me', icon: Icons.person_rounded),
      if (_formats.contains('couples')) (key: 'couples', label: 'Me & my partner', icon: Icons.favorite_rounded),
      if (_formats.contains('family')) (key: 'family', label: 'My family', icon: Icons.family_restroom_rounded),
      if (_offersMinors) (key: 'minor', label: 'My child', icon: Icons.child_care_rounded),
    ];
    final showWho = options.length > 1 || _format != 'individual';

    if (!showWho && !_requiresRecipe) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWho) ...[
          Text('Who is this session for?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  avatar: Icon(o.icon, size: 16),
                  label: Text(o.label),
                  selected: _format == o.key,
                  onSelected: (_) => _pick(o.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_format == 'minor') _childPicker(theme, required: true),
          if (_format == 'couples') _partnerFields(theme),
          if (_format == 'family') _familyFields(theme),
        ],
        if (_requiresRecipe) ...[
          if (showWho) const SizedBox(height: 20),
          _recipePicker(theme),
        ],
        if (!_loading && _problem != null) ...[
          const SizedBox(height: 10),
          Text(_problem!, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.accentDeep)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _childPicker(ThemeData theme, {required bool required}) {
    if (_loading) return const LinearProgressIndicator(minHeight: 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dependents.isEmpty)
          Text(
            'Add your child to your account first. As their parent or guardian you book and pay; they join the session with you.',
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
        for (final d in _dependents)
          Builder(builder: (context) {
            final id = (d['id'] as num).toInt();
            final ok = _servesDependent(d);
            return RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: id,
              groupValue: _dependentId,
              toggleable: !required,
              onChanged: ok
                  ? (v) {
                      setState(() => _dependentId = v);
                      _emit();
                    }
                  : null,
              title: Text('${d['name']} · ${d['age']}'),
              subtitle: ok ? null : const Text('This professional does not work with this age group'),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              await context.push('/family');
              if (mounted) _load();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(_dependents.isEmpty ? 'Add my child' : 'Add another child'),
          ),
        ),
      ],
    );
  }

  Widget _partnerFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _partnerName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Partner's name"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _partnerEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Partner's email (optional)"),
        ),
        const SizedBox(height: 8),
        Text(
          'We email your partner an invitation so they can join from their own phone. '
          'Leave it empty if you will sit together on one device. You pay once for both of you.',
          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
        ),
      ],
    );
  }

  Widget _familyFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add relatives who will join from their own device. Anyone sitting with you does not need an invitation.',
          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
        ),
        for (var i = 0; i < _family.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _family[i].name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _family[i].email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    final row = _family.removeAt(i);
                    row.name.dispose();
                    row.email.dispose();
                    _emit();
                  },
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _family.length >= 5 ? null : _addFamilyMember,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Invite a family member'),
          ),
        ),
        if (_dependents.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Is one of your children part of it?', style: theme.textTheme.labelLarge),
          _childPicker(theme, required: false),
        ],
      ],
    );
  }

  Widget _recipePicker(ThemeData theme) {
    final lead = (_pro['cooking_min_lead_hours'] as num?)?.toInt() ?? 24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What will you cook?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'You cook along at home, so you need the ingredients ready. '
          'Pick a time at least $lead hours away to leave time for shopping.',
          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
        ),
        const SizedBox(height: 10),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        for (final r in _recipes)
          Builder(builder: (context) {
            final id = (r['id'] as num).toInt();
            final selected = _recipeId == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CandyCard(
                tint: selected ? FriendColors.accent : null,
                accentStripe: selected,
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                onTap: () {
                  setState(() => _recipeId = id);
                  _emit();
                },
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: selected ? FriendColors.accentDeep : FriendColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((r['title'] ?? '').toString(), style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          RecipeMetaRow(recipe: r),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/recipes/$id'),
                      child: const Text('Ingredients'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
