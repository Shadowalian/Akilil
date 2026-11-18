import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

final myProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/professional-profile');
  return res.data ?? const {};
});

final myRecipesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/recipes');
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

final _myStreamsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/live-streams', queryParameters: {'mine': 1});
  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
});

/* ───────────────────────────── Recipes (chefs) ───────────────────────────── */

/// A chef's recipes. Every cooking session must point at a published one.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRecipesProvider);
    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(tr('My recipes'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/recipes/new');
          ref.invalidate(myRecipesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('New recipe')),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FriendEmptyState(
          icon: Icons.restaurant_menu_rounded,
          title: tr('Recipes are for chefs'),
          message: e is DioException ? apiErrorMessage(e.response?.data) : null,
        ),
        data: (list) => list.isEmpty
            ? FriendEmptyState(
                icon: Icons.restaurant_menu_rounded,
                title: tr('No recipes yet'),
                message: tr('Clients need a published recipe to book you, so they can shop before cooking with you.'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  for (final r in list)
                    Card(
                      child: ListTile(
                        title: Text((r['title'] ?? '').toString()),
                        subtitle: RecipeMetaRow(recipe: r),
                        trailing: FriendStatusChip(
                          label: (r['status'] ?? '').toString(),
                          color: r['status'] == 'published' ? FriendColors.primary : FriendColors.textMuted,
                        ),
                        onTap: () async {
                          await context.push('/recipes/${r['id']}');
                          ref.invalidate(myRecipesProvider);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Create or edit a recipe: details, ingredients, steps, publish.
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, this.recipeId});
  final String? recipeId;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _IngredientRow {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final unit = TextEditingController();
  final substitute = TextEditingController();
  bool optional = false;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    substitute.dispose();
  }
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _servings = TextEditingController(text: '2');
  final _prep = TextEditingController(text: '15');
  final _cook = TextEditingController(text: '30');
  final _allergens = TextEditingController();
  final _equipment = TextEditingController();
  final List<_IngredientRow> _ingredients = [];
  final List<TextEditingController> _steps = [];
  String _status = 'draft';
  bool _loading = false;
  bool _saving = false;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    if (widget.recipeId != null) {
      _loading = true;
      _load();
    } else {
      _ingredients.add(_IngredientRow());
      _steps.add(TextEditingController());
    }
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/recipes/${widget.recipeId}');
      final r = (res.data?['recipe'] as Map?)?.cast<String, dynamic>() ?? const {};
      _title.text = (r['title'] ?? '').toString();
      _description.text = (r['description'] ?? '').toString();
      _servings.text = '${r['servings'] ?? 2}';
      _prep.text = '${r['prep_minutes'] ?? 0}';
      _cook.text = '${r['cook_minutes'] ?? 0}';
      _allergens.text = ((r['allergens'] as List?) ?? const []).join(', ');
      _equipment.text = ((r['equipment'] as List?) ?? const []).join(', ');
      _status = (r['status'] ?? 'draft').toString();
      for (final i in (r['ingredients'] as List?) ?? const []) {
        final row = _IngredientRow()
          ..name.text = (i['name'] ?? '').toString()
          ..quantity.text = (i['quantity'] ?? '').toString()
          ..unit.text = (i['unit'] ?? '').toString()
          ..substitute.text = (i['substitute'] ?? '').toString()
          ..optional = i['is_optional'] == true;
        _ingredients.add(row);
      }
      for (final s in (r['steps'] as List?) ?? const []) {
        _steps.add(TextEditingController(text: (s['instruction'] ?? '').toString()));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _servings, _prep, _cook, _allergens, _equipment, ..._steps]) {
      c.dispose();
    }
    for (final i in _ingredients) {
      i.dispose();
    }
    super.dispose();
  }

  List<String> _csv(String text) => text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save({required bool publish}) async {
    setState(() => _saving = true);
    final payload = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'servings': int.tryParse(_servings.text) ?? 2,
      'prep_minutes': int.tryParse(_prep.text) ?? 0,
      'cook_minutes': int.tryParse(_cook.text) ?? 0,
      'allergens': _csv(_allergens.text),
      'equipment': _csv(_equipment.text),
      'ingredients': [
        for (final i in _ingredients)
          if (i.name.text.trim().isNotEmpty)
            {
              'name': i.name.text.trim(),
              'quantity': i.quantity.text.trim(),
              'unit': i.unit.text.trim(),
              'substitute': i.substitute.text.trim(),
              'is_optional': i.optional,
            },
      ],
      'steps': [
        for (final s in _steps)
          if (s.text.trim().isNotEmpty) {'instruction': s.text.trim()},
      ],
      'publish': publish,
    };
    try {
      if (widget.recipeId == null) {
        await _dio.post('/recipes', data: payload);
      } else {
        await _dio.put('/recipes/${widget.recipeId}', data: payload);
      }
      if (!mounted) return;
      _toast(context, publish ? 'Published' : tr('Saved'));
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(context, apiErrorMessage(e.response?.data, tr('Could not save')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    Widget num(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label),
          ),
        );

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(widget.recipeId == null ? 'New recipe' : tr('Edit recipe'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _save(publish: false),
                  child: Text(_status == 'published' ? 'Save' : tr('Save draft')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(publish: true),
                  child: Text(_status == 'published' ? 'Update' : tr('Publish')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: InputDecoration(labelText: tr('Dish name'))),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(labelText: tr('What people will learn')),
          ),
          const SizedBox(height: 10),
          Row(children: [
            num(_servings, tr('Serves')),
            const SizedBox(width: 8),
            num(_prep, tr('Prep min')),
            const SizedBox(width: 8),
            num(_cook, tr('Cook min')),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _allergens,
            decoration: InputDecoration(labelText: tr('Allergens (comma separated)'), hintText: tr('gluten, nuts')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _equipment,
            decoration: InputDecoration(labelText: tr('Equipment (comma separated)'), hintText: tr('large pot, mitad')),
          ),
          const SizedBox(height: 20),
          Text(tr('Ingredients'), style: theme.textTheme.titleMedium),
          Text(
            tr('This is the shopping list participants see. It locks 24 hours before a session that uses it.'),
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          for (var i = 0; i < _ingredients.length; i++)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredients[i].name,
                          decoration: InputDecoration(labelText: trx('Ingredient ${i + 1}', 'ግብዓት ${i + 1}')),
                        ),
                      ),
                      IconButton(
                        tooltip: tr('Remove'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _ingredients.removeAt(i).dispose()),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      SizedBox(
                        width: 84,
                        child: TextField(
                          controller: _ingredients[i].quantity,
                          decoration: InputDecoration(labelText: tr('Amount')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        child: TextField(
                          controller: _ingredients[i].unit,
                          decoration: InputDecoration(labelText: tr('Unit')),
                        ),
                      ),
                      const Spacer(),
                      FilterChip(
                        label: Text(tr('Optional')),
                        showCheckmark: false,
                        selected: _ingredients[i].optional,
                        onSelected: (v) => setState(() => _ingredients[i].optional = v),
                      ),
                      const SizedBox(width: 8),
                    ]),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: _ingredients[i].substitute,
                        decoration: InputDecoration(labelText: tr('Substitute if hard to find (optional)')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _ingredients.add(_IngredientRow())),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('Add ingredient')),
          ),
          const SizedBox(height: 12),
          Text(tr('Method'), style: theme.textTheme.titleMedium),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _steps[i],
                maxLines: null,
                decoration: InputDecoration(
                  labelText: trx('Step ${i + 1}', 'ደረጃ ${i + 1}'),
                  suffixIcon: IconButton(
                    tooltip: tr('Remove'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _steps.removeAt(i).dispose()),
                  ),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _steps.add(TextEditingController())),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('Add step')),
          ),
        ],
      ),
    );
  }
}

/// Lets the host pick one of their published recipes. Returns its id.
Future<int?> pickPublishedRecipe(BuildContext context, WidgetRef ref) async {
  List<Map<String, dynamic>> recipes = const [];
  try {
    final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/recipes', queryParameters: {'status': 'published'});
    recipes = ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  } catch (_) {}
  if (!context.mounted) return null;
  if (recipes.isEmpty) {
    _toast(context, tr('Publish a recipe first — cooking sessions need one.'));
    context.push('/recipes');
    return null;
  }
  return showModalBottomSheet<int>(
    context: context,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(tr('Which recipe will you cook?'))),
          for (final r in recipes)
            ListTile(
              leading: const Icon(Icons.restaurant_menu_rounded),
              title: Text((r['title'] ?? '').toString()),
              subtitle: RecipeMetaRow(recipe: r),
              onTap: () => Navigator.pop(sheet, (r['id'] as num).toInt()),
            ),
        ],
      ),
    ),
  );
}

/// Date + time picker returning a local DateTime.
Future<DateTime?> pickDateTime(BuildContext context, {required DateTime earliest}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: earliest,
    firstDate: earliest,
    lastDate: earliest.add(const Duration(days: 120)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(earliest));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/* ───────────────────────────── Going live ───────────────────────────── */

/// The host's broadcasts: go live now (spiritual guides), schedule one,
/// start a scheduled one.
class LiveStudioScreen extends ConsumerWidget {
  const LiveStudioScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref, Map<String, dynamic> profile) async {
    final isChef = profile['is_chef'] == true;
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(isChef ? 'Schedule a live cook-along' : tr('New live broadcast')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, autofocus: true, decoration: InputDecoration(labelText: tr('Title'))),
            const SizedBox(height: 8),
            Text(
              isChef
                  ? tr('Viewers need time to shop, so cook-alongs are announced at least 24 hours ahead with their recipe.')
                  : tr('Go live now, or pick a time so people can plan to join.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
          if (!isChef) TextButton(onPressed: () => Navigator.pop(d, false), child: Text(tr('Go live now'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(tr('Schedule'))),
        ],
      ),
    );
    if (ok == null || title.text.trim().length < 3 || !context.mounted) return;

    int? recipeId;
    DateTime? when;
    if (isChef) {
      recipeId = await pickPublishedRecipe(context, ref);
      if (recipeId == null || !context.mounted) return;
    }
    if (ok) {
      when = await pickDateTime(
        context,
        earliest: DateTime.now().add(Duration(hours: isChef ? 25 : 1)),
      );
      if (when == null || !context.mounted) return;
    }
    try {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>('/live-streams', data: {
        'title': title.text.trim(),
        if (when != null) 'scheduled_at': when.toUtc().toIso8601String(),
        if (recipeId != null) 'recipe_id': recipeId,
      });
      ref.invalidate(_myStreamsProvider);
      if (!context.mounted) return;
      if (!ok) context.push('/live/${res.data?['stream']?['id']}/host');
    } on DioException catch (e) {
      if (context.mounted) _toast(context, apiErrorMessage(e.response?.data, tr('Could not create broadcast')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull ?? const {};
    final async = ref.watch(_myStreamsProvider);
    final canGoLive = profile['can_go_live'] == true;

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(tr('Go live'))),
      floatingActionButton: canGoLive
          ? FloatingActionButton.extended(
              onPressed: () => _create(context, ref, profile),
              icon: const Icon(Icons.sensors_rounded),
              label: Text(tr('New broadcast')),
            )
          : null,
      body: !canGoLive && profile.isNotEmpty
          ? FriendEmptyState(
              icon: Icons.lock_outline_rounded,
              title: tr('Live is for spiritual guides and chefs'),
              message: tr('Clinical sessions are private and are never broadcast.'),
            )
          : async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const FriendEmptyState(icon: Icons.cloud_off_outlined, title: "Couldn't load broadcasts"),
              data: (list) => list.isEmpty
                  ? FriendEmptyState(
                      icon: Icons.sensors_rounded,
                      title: tr('No broadcasts yet'),
                      message: tr('Go live to teach, reflect or cook with many people at once. Viewers can send gifts.'),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(_myStreamsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        children: [
                          for (final s in list)
                            Card(
                              child: ListTile(
                                title: Text((s['title'] ?? '').toString()),
                                subtitle: Text([
                                  (s['status'] ?? '').toString(),
                                  if (DateTime.tryParse('${s['scheduled_at']}') case final d?)
                                    trDate('EEE MMM d · h:mm a', d.toLocal()),
                                  if (s['status'] == 'ended')
                                    '${s['total_viewers']} viewers · gifts ${formatMoney(s['gifts_total_cents'] as num?)}',
                                ].join(' · ')),
                                trailing: (s['status'] == 'scheduled' || s['status'] == 'live')
                                    ? FilledButton(
                                        onPressed: () async {
                                          await context.push('/live/${s['id']}/host');
                                          ref.invalidate(_myStreamsProvider);
                                        },
                                        child: Text(s['status'] == 'live' ? 'Rejoin' : tr('Start')),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

/// On air: the host's camera with the live chrome, takings and moderation.
class LiveHostScreen extends ConsumerStatefulWidget {
  const LiveHostScreen({super.key, required this.streamId});
  final String streamId;

  @override
  ConsumerState<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends ConsumerState<LiveHostScreen> {
  LiveFeedController? _feed;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _stream;
  String? _error;

  Dio get _dio => ref.read(dioProvider);
  String get _base => '/live-streams/${widget.streamId}';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final res = await _dio.post<Map<String, dynamic>>('$_base/start');
      if (!mounted) return;
      setState(() {
        _session = (res.data?['session'] as Map?)?.cast<String, dynamic>();
        _stream = (res.data?['stream'] as Map?)?.cast<String, dynamic>();
        _feed = LiveFeedController(dio: _dio, streamId: int.parse(widget.streamId))..start();
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e.response?.data, "Couldn't start the broadcast"));
    }
  }

  Future<void> _end() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('End the broadcast?')),
        content: Text(tr('Everyone watching will be disconnected.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(tr('Keep going'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(tr('End'))),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await _dio.post('$_base/end');
    } catch (_) {}
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _feed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FriendEmptyState(
          icon: Icons.sensors_off_rounded,
          title: "Can't go live yet",
          message: _error,
          ctaLabel: tr('Try again'),
          onCta: _start,
        ),
      );
    }
    final feed = _feed;
    final session = _session;
    if (feed == null || session == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    final stream = _stream ?? const {};
    return Scaffold(
      backgroundColor: Colors.black,
      body: LiveRoomView(
        controller: feed,
        roomUrl: session['room_url'] as String,
        jwt: session['token'] as String?,
        displayName: (stream['host'] as Map?)?['name']?.toString(),
        isHost: true,
        hostName: ((stream['host'] as Map?)?['name'] ?? tr('You')).toString(),
        title: (stream['title'] ?? '').toString(),
        recipeTitle: (stream['recipe'] as Map?)?['title']?.toString(),
        onClose: () => context.pop(),
        onEnd: _end,
        onRemoveComment: (item) => _dio.delete('/live-stream-events/${item.id}').ignore(),
        onRemoveViewer: (item) {
          if (item.userId != null) _dio.post('$_base/viewers/${item.userId}/ban').ignore();
        },
        onToggleComments: (v) => _dio.put(_base, data: {'allow_comments': v}).ignore(),
        onToggleGifts: (v) => _dio.put(_base, data: {'allow_gifts': v}).ignore(),
      ),
    );
  }
}

/* ───────────────────────────── Who I work with ───────────────────────────── */

/// Session formats and client age groups this professional accepts.
class CareSettingsScreen extends ConsumerStatefulWidget {
  const CareSettingsScreen({super.key});

  @override
  ConsumerState<CareSettingsScreen> createState() => _CareSettingsScreenState();
}

class _CareSettingsScreenState extends ConsumerState<CareSettingsScreen> {
  Set<String> _formats = {'individual'};
  Set<String> _ages = {'adults'};
  final _couples = TextEditingController();
  final _family = TextEditingController();
  final _bio = TextEditingController();
  final _rate = TextEditingController();
  bool _accepting = true;
  String _currency = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/professional-profile');
      final p = res.data ?? const {};
      _formats = ((p['care_formats'] as List?) ?? const ['individual']).map((e) => '$e').toSet();
      _ages = ((p['age_groups'] as List?) ?? const ['adults']).map((e) => '$e').toSet();
      _currency = (p['currency'] ?? '').toString();
      _bio.text = (p['bio'] ?? '').toString();
      _rate.text = '${((p['hourly_rate_cents'] as num?) ?? 0) / 100}';
      _accepting = p['is_accepting_clients'] != false;
      if (p['couples_rate_cents'] != null) _couples.text = '${(p['couples_rate_cents'] as num) / 100}';
      if (p['family_rate_cents'] != null) _family.text = '${(p['family_rate_cents'] as num) / 100}';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  int? _cents(String text) {
    final v = double.tryParse(text.trim());
    return v == null ? null : (v * 100).round();
  }

  Future<void> _save() async {
    try {
      await ref.read(dioProvider).put('/me/professional-profile', data: {
        'bio': _bio.text.trim(),
        'hourly_rate_cents': _cents(_rate.text) ?? 0,
        'is_accepting_clients': _accepting,
        'care_formats': _formats.toList(),
        'age_groups': _ages.toList(),
        'couples_rate_cents': _cents(_couples.text),
        'family_rate_cents': _cents(_family.text),
      });
      if (!mounted) return;
      _toast(context, tr('Saved'));
      context.pop();
    } on DioException catch (e) {
      if (mounted) _toast(context, apiErrorMessage(e.response?.data));
    }
  }

  @override
  void dispose() {
    _couples.dispose();
    _family.dispose();
    _bio.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Widget chips(Map<String, String> options, Set<String> selected) => Wrap(
          spacing: 8,
          children: [
            for (final o in options.entries)
              FilterChip(
                label: Text(o.value),
                showCheckmark: false,
                selected: selected.contains(o.key),
                onSelected: (v) => setState(() => v ? selected.add(o.key) : selected.remove(o.key)),
              ),
          ],
        );

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(tr('Practice profile'))),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Accepting new clients')),
            subtitle: Text(tr('Turn off to pause new bookings')),
            value: _accepting,
            onChanged: (v) => setState(() => _accepting = v),
          ),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 600,
            decoration: InputDecoration(labelText: tr('About you'), alignLabelWithHint: true),
          ),
          TextField(
            controller: _rate,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: trx('Price per session ($_currency)', 'የአንድ ቆይታ ዋጋ ($_currency)')),
          ),
          SizedBox(height: 20),
          Text(tr('Session formats'), style: theme.textTheme.titleMedium),
          SizedBox(height: 8),
          chips({
            'individual': tr('Individual'),
            'couples': tr('Couples / marriage'),
            'family': tr('Family'),
            'child': tr('Children'),
            'teen': tr('Teens'),
          }, _formats),
          SizedBox(height: 20),
          Text(tr('Age groups'), style: theme.textTheme.titleMedium),
          SizedBox(height: 8),
          chips({'children': tr('Children (0–12)'), 'teens': tr('Teens (13–17)'), 'adults': tr('Adults')}, _ages),
          const SizedBox(height: 8),
          Text(
            tr('Only offer what you are trained and licensed for. Sessions for minors are always booked and paid for by a parent or guardian.'),
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _couples,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: trx('Couples session price ($_currency)', 'የጥንዶች ቆይታ ዋጋ ($_currency)'), hintText: tr('Same as individual')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _family,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: trx('Family session price ($_currency)', 'የቤተሰብ ቆይታ ዋጋ ($_currency)'), hintText: tr('Same as individual')),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _formats.isEmpty || _ages.isEmpty ? null : _save, child: Text(tr('Save'))),
        ],
      ),
    );
  }
}
