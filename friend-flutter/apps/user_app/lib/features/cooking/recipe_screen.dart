import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chef's recipe as a shopping checklist. Opened from a booking, a class
/// or a live stream; with [appointmentId] / [meetingId] it also carries the
/// "I have my ingredients" confirmation that unlocks joining.
class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key, required this.recipeId, this.appointmentId, this.meetingId});

  final String recipeId;
  final String? appointmentId;
  final String? meetingId;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  Map<String, dynamic>? _recipe;
  Set<int> _checked = {};
  bool _loading = true;
  bool _confirming = false;

  Dio get _dio => ref.read(dioProvider);
  bool get _canConfirm => widget.appointmentId != null || widget.meetingId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/recipes/${widget.recipeId}');
      final c = await _dio.get<Map<String, dynamic>>('/recipes/${widget.recipeId}/checklist');
      if (!mounted) return;
      setState(() {
        _recipe = (r.data?['recipe'] as Map?)?.cast<String, dynamic>();
        _checked = ((c.data?['checked_ingredient_ids'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _ingredients =>
      ((_recipe?['ingredients'] as List?) ?? const []).cast<Map<String, dynamic>>();

  int get _missingRequired => _ingredients
      .where((i) => i['is_optional'] != true && !_checked.contains((i['id'] as num).toInt()))
      .length;

  void _toggle(int id, bool checked) {
    setState(() => checked ? _checked.add(id) : _checked.remove(id));
    _dio.put('/recipes/${widget.recipeId}/checklist', data: {'checked_ingredient_ids': _checked.toList()}).ignore();
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      await _dio.post(widget.appointmentId != null
          ? '/appointments/${widget.appointmentId}/ingredients/confirm'
          : '/therapy-group-meetings/${widget.meetingId}/ingredients/confirm');
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e.response?.data))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = _recipe;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const FriendEmptyState(icon: Icons.restaurant_menu_rounded, title: 'Recipe not available'),
      );
    }
    final steps = ((recipe['steps'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final equipment = ((recipe['equipment'] as List?) ?? const []).join(', ');
    final missing = _missingRequired;

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: const Text('Recipe')),
      bottomNavigationBar: !_canConfirm
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: missing == 0 && !_confirming ? _confirm : null,
                  child: Text(missing == 0
                      ? 'I have my ingredients — ready to cook'
                      : '$missing ingredient${missing == 1 ? '' : 's'} still to get'),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text((recipe['title'] ?? '').toString(), style: theme.textTheme.headlineSmall),
          if (recipe['chef'] is Map)
            Text('with ${(recipe['chef'] as Map)['name']}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          RecipeMetaRow(recipe: recipe),
          const SizedBox(height: 10),
          RecipeTagWrap(recipe: recipe),
          if ((recipe['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(recipe['description'].toString(), style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Text('Shopping list', style: theme.textTheme.titleMedium),
          Text(
            'Tick things off as you get them. Have everything out before the session starts.',
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          RecipeIngredientList(ingredients: _ingredients, checkedIds: _checked, onToggle: _toggle),
          if (equipment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('You will also need', style: theme.textTheme.titleMedium),
            Text(equipment, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Text('Method', style: theme.textTheme.titleMedium),
          RecipeStepList(steps: steps),
        ],
      ),
    );
  }
}
