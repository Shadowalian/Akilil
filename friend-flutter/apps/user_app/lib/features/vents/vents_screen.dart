import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';




import 'package:core/core.dart';



final _ventsProvider =

    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {

  final dio = ref.read(dioProvider);

  final res = await dio.get<Map<String, dynamic>>('/vents');

  return ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();

});



/// Vents — a private pressure valve. The backend only ever returns the user's

/// own vents, so this list is nobody else's business, which is exactly why the

/// composer sits right at the top with no ceremony around it.

class VentsScreen extends ConsumerStatefulWidget {

  const VentsScreen({super.key});



  @override

  ConsumerState<VentsScreen> createState() => _VentsScreenState();

}



class _VentsScreenState extends ConsumerState<VentsScreen> {

  final _controller = TextEditingController();

  bool _sending = false;



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  Future<void> _send() async {

    final content = _controller.text.trim();

    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {

      await ref.read(dioProvider).post('/vents', data: {

        'content_type': 'text',

        'content': content,

        'is_anonymous': false,

      });

      _controller.clear();

      ref.invalidate(_ventsProvider);

    } on DioException catch (e) {

      final msg = e.response?.data is Map

          ? (e.response!.data['message'] as String? ?? "Couldn't save that.")

          : "Couldn't save that.";

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    } finally {

      if (mounted) setState(() => _sending = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final async = ref.watch(_ventsProvider);



    return FriendPageScaffold(

      eyebrow: tr('Release'),

      title: tr('Let it out'),

      subtitle: tr('Only you can see this. No replies, no fixing.'),

      onRefresh: () async => ref.invalidate(_ventsProvider),

      body: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          CandyCard(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [

                TextField(

                  controller: _controller,

                  minLines: 3,

                  maxLines: 8,

                  textCapitalization: TextCapitalization.sentences,

                  decoration: const InputDecoration(

                    hintText: "What's sitting on your chest?",

                    border: InputBorder.none,

                  ),

                ),

                const SizedBox(height: 8),

                FriendGlowButton(

                  label: tr('Release'),

                  icon: Icons.send,

                  onPressed: _sending ? null : _send,

                ),

              ],

            ),

          ),

          const SizedBox(height: 24),

          async.when(

            loading: () => const Padding(

              padding: EdgeInsets.symmetric(vertical: 32),

              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),

            ),

            error: (_, __) => FriendEmptyState(

              icon: Icons.cloud_off_outlined,

              title: "Couldn't load your vents",

              message: tr('Check your connection and try again.'),

            ),

            data: (vents) {

              if (vents.isEmpty) {

                return FriendEmptyState(

                  icon: Icons.air,

                  title: tr('Nothing here yet'),

                  message: tr('Whatever you write stays between you and you.'),

                );

              }

              return Column(

                children: [

                  for (final v in vents) ...[

                    _VentCard(vent: v),

                    const SizedBox(height: 12),

                  ],

                ],

              );

            },

          ),

        ],

      ),

    );

  }

}



class _VentCard extends StatelessWidget {

  const _VentCard({required this.vent});

  final Map<String, dynamic> vent;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final created = DateTime.tryParse(vent['created_at'] as String? ?? '');

    final isVoice = vent['content_type'] == 'voice';



    return CandyCard(

      accentStripe: true,

      tint: FriendColors.accent,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          if (created != null)

            Text(

              trDate('MMM d • h:mm a', created),

              style: theme.textTheme.bodySmall,

            ),

          const SizedBox(height: 6),

          Text(

            isVoice

                ? 'Voice vent · ${vent['voice_duration_seconds'] ?? '—'}s'

                : (vent['content'] as String? ?? ''),

            style: theme.textTheme.bodyMedium,

          ),

        ],

      ),

    );

  }

}

