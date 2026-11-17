import '../util/i18n.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

String _amount(Map<String, dynamic> ingredient) {
  final quantity = (ingredient['quantity'] ?? '').toString().trim();
  final unit = (ingredient['unit'] ?? '').toString().trim();
  return [quantity, unit].where((s) => s.isNotEmpty).join(' ');
}

/// One-line facts under a recipe title: time, servings, difficulty.
class RecipeMetaRow extends StatelessWidget {
  const RecipeMetaRow({super.key, required this.recipe, this.color});

  final Map<String, dynamic> recipe;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final total = (recipe['total_minutes'] as num?)?.toInt() ?? 0;
    final servings = (recipe['servings'] as num?)?.toInt();
    final count = (recipe['ingredient_count'] as num?)?.toInt() ?? (recipe['ingredients'] as List?)?.length;
    final c = color ?? FriendColors.textSecondary;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: c);

    Widget fact(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 14, color: c), const SizedBox(width: 4), Text(text, style: style)],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        if (total > 0) fact(Icons.schedule_rounded, coreTr('{n} min').replaceAll('{n}', '$total')),
        if (servings != null) fact(Icons.people_outline_rounded, coreTr('Serves {n}').replaceAll('{n}', '$servings')),
        if (count != null) fact(Icons.shopping_basket_outlined, coreTr('{n} ingredients').replaceAll('{n}', '$count')),
        if ((recipe['difficulty'] ?? '').toString().isNotEmpty)
          fact(Icons.local_fire_department_outlined, recipe['difficulty'].toString()),
      ],
    );
  }
}

/// The ingredient list. With [onToggle] it becomes a shopping checklist.
class RecipeIngredientList extends StatelessWidget {
  const RecipeIngredientList({
    super.key,
    required this.ingredients,
    this.checkedIds = const {},
    this.onToggle,
  });

  final List<Map<String, dynamic>> ingredients;
  final Set<int> checkedIds;

  /// Called with the ingredient id and its new checked state.
  final void Function(int id, bool checked)? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final ing in ingredients)
          Builder(builder: (context) {
            final id = (ing['id'] as num?)?.toInt() ?? -1;
            final checked = checkedIds.contains(id);
            final optional = ing['is_optional'] == true;
            final amount = _amount(ing);
            final note = (ing['note'] ?? '').toString();
            final substitute = (ing['substitute'] ?? '').toString();

            final title = Text.rich(
              TextSpan(children: [
                TextSpan(text: (ing['name'] ?? '').toString()),
                if (optional)
                  TextSpan(text: '  ${coreTr('optional')}', style: theme.textTheme.labelSmall?.copyWith(color: FriendColors.textMuted)),
              ]),
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? FriendColors.textMuted : null,
              ),
            );
            final details = [
              if (note.isNotEmpty) note,
              if (substitute.isNotEmpty) coreTr('No luck finding it? Use {x}').replaceAll('{x}', substitute),
            ].join('\n');

            return InkWell(
              onTap: onToggle == null ? null : () => onToggle!(id, !checked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onToggle != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12, top: 1),
                        child: Icon(
                          checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: checked ? FriendColors.primary : FriendColors.textMuted,
                          size: 22,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 12, top: 8),
                        child: Icon(Icons.circle, size: 6, color: FriendColors.accent),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          if (details.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                details,
                                style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (amount.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          amount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: FriendColors.primaryDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

/// Numbered method.
class RecipeStepList extends StatelessWidget {
  const RecipeStepList({super.key, required this.steps});

  final List<Map<String, dynamic>> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: FriendColors.primaryLight, shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.primaryDeep, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((steps[i]['instruction'] ?? '').toString(), style: theme.textTheme.bodyLarge),
                      if (steps[i]['duration_minutes'] != null)
                        Text(
                          coreTr('{n} min').replaceAll('{n}', '${steps[i]['duration_minutes']}'),
                          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Allergen / dietary tag chips.
class RecipeTagWrap extends StatelessWidget {
  const RecipeTagWrap({super.key, required this.recipe});

  final Map<String, dynamic> recipe;

  @override
  Widget build(BuildContext context) {
    final dietary = ((recipe['dietary_tags'] as List?) ?? const []).map((e) => e.toString());
    final allergens = ((recipe['allergens'] as List?) ?? const []).map((e) => e.toString());
    if (dietary.isEmpty && allergens.isEmpty) return const SizedBox.shrink();

    Widget chip(String label, {required bool warn}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: warn ? FriendColors.errorContainer : FriendColors.primaryLight,
            borderRadius: BorderRadius.circular(FriendRadii.pill),
          ),
          child: Text(
            warn ? coreTr('Contains {x}').replaceAll('{x}', label) : label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: warn ? FriendColors.onErrorContainer : FriendColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in dietary) chip(t, warn: false),
        for (final a in allergens) chip(a, warn: true),
      ],
    );
  }
}
