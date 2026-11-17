import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:core/core.dart';



final _goalsProvider =

    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {

  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/goals');

  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();

});



final _habitsProvider =

    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {

  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/habits');

  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();

});



/// Goals & habits on one surface — they answer the same question ("what am I

/// working towards?") at two different time scales, and splitting them across

/// tabs made both feel emptier than they are.

class GoalsHabitsScreen extends ConsumerWidget {

  const GoalsHabitsScreen({super.key});



  Future<void> _add(

    BuildContext context,

    WidgetRef ref, {

    required String path,

    required String label,

    required ProviderOrFamily toInvalidate,

  }) async {

    final controller = TextEditingController();

    final title = await showDialog<String>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text(trx('New $label', label == 'goal' ? 'አዲስ ግብ' : 'አዲስ ልማድ')),

        content: TextField(

          controller: controller,

          autofocus: true,

          textCapitalization: TextCapitalization.sentences,

          decoration: InputDecoration(hintText: trx('Name this $label', label == 'goal' ? 'ግቡን ይሰይሙ' : 'ልማዱን ይሰይሙ')),

          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx),

            child: Text(tr('Cancel')),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(ctx, controller.text.trim()),

            child: Text(tr('Add')),

          ),

        ],

      ),

    );

    controller.dispose();

    if (title == null || title.isEmpty) return;



    try {

      await ref.read(dioProvider).post(path, data: {'title': title});

      ref.invalidate(toInvalidate);

    } on DioException {

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(trx("Couldn't add that $label.", 'መጨመር አልተቻለም።'))),

      );

    }

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final goals = ref.watch(_goalsProvider);

    final habits = ref.watch(_habitsProvider);



    return FriendPageScaffold(

      eyebrow: tr('Growth'),

      title: tr('What you\'re building'),

      subtitle: tr('Big things you\'re heading towards, small things you repeat.'),

      onRefresh: () async {

        ref.invalidate(_goalsProvider);

        ref.invalidate(_habitsProvider);

      },

      body: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          _Section(

            title: tr('Goals'),

            icon: Icons.flag_outlined,

            emptyMessage: tr('Name one thing you\'re moving towards.'),

            async: goals,

            onAdd: () => _add(context, ref,

                path: '/goals', label: 'goal', toInvalidate: _goalsProvider),

            subtitleFor: (g) {

              final progress = (g['progress'] as num?)?.toInt();

              return progress == null ? null : '$progress% there';

            },

          ),

          const SizedBox(height: 16),

          _Section(

            title: tr('Habits'),

            icon: Icons.repeat,

            emptyMessage: tr('Small things, repeated, add up.'),

            async: habits,

            onAdd: () => _add(context, ref,

                path: '/habits', label: 'habit', toInvalidate: _habitsProvider),

            subtitleFor: (h) => h['cadence'] as String?,

          ),

        ],

      ),

    );

  }

}



class _Section extends StatelessWidget {

  const _Section({

    required this.title,

    required this.icon,

    required this.emptyMessage,

    required this.async,

    required this.onAdd,

    required this.subtitleFor,

  });



  final String title;

  final IconData icon;

  final String emptyMessage;

  final AsyncValue<List<Map<String, dynamic>>> async;

  final VoidCallback onAdd;

  final String? Function(Map<String, dynamic>) subtitleFor;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Row(

          children: [

            Expanded(child: Text(title, style: theme.textTheme.headlineSmall)),

            FriendGlowButton(label: tr('Add'), icon: Icons.add, onPressed: onAdd),

          ],

        ),

        const SizedBox(height: 12),

        async.when(

          loading: () => const Padding(

            padding: EdgeInsets.symmetric(vertical: 20),

            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),

          ),

          error: (_, __) => CandyCard(

            child: Text(

              "Couldn't load ${title.toLowerCase()}.",

              style: theme.textTheme.bodyMedium,

            ),

          ),

          data: (items) {

            if (items.isEmpty) {

              return CandyCard(

                padding: EdgeInsets.zero,

                child: FriendEmptyState(

                  icon: icon,

                  title: trx('No ${title.toLowerCase()} yet', 'እስካሁን ምንም የለም'),

                  message: emptyMessage,

                ),

              );

            }

            return Column(

              children: [

                for (final item in items) ...[

                  CandyCard(

                    accentStripe: true,

                    child: Row(

                      children: [

                        Icon(icon, color: FriendColors.primary),

                        const SizedBox(width: 14),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                item['title'] as String? ?? tr('Untitled'),

                                style: theme.textTheme.bodyLarge,

                              ),

                              if (subtitleFor(item) != null)

                                Text(

                                  subtitleFor(item)!,

                                  style: theme.textTheme.bodySmall?.copyWith(

                                    color: FriendColors.textSecondary,

                                  ),

                                ),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 10),

                ],

              ],

            );

          },

        ),

      ],

    );

  }

}

