import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import 'help_request.dart';
import 'safety_plan_store.dart';
import '../worksheets/box_breathing_dialog.dart';

class CrisisScreen extends ConsumerWidget {
  const CrisisScreen({super.key});

  Future<void> _handleAction(
    BuildContext context,
    Map<String, dynamic> resource,
  ) async {
    final type = resource['action_type'] as String;
    final target = resource['action_target'] as String;

    try {
      if (type == 'call') {
        final uri = Uri.parse('tel:$target');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else if (type == 'sms') {
        final body = resource['body'] as String? ?? '';
        final uri = Uri.parse('sms:$target?body=$body');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else if (type == 'url') {
        final uri = Uri.parse(target);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trx('Contact: $target', 'ይደውሉ፦ $target'))),
      );
    }
  }

  /// Help outside Ethiopia. The Ethiopian numbers sit at the top of the
  /// screen. Review with a local clinical advisor before launch.
  static List<Map<String, dynamic>> get _resources => <Map<String, dynamic>>[
        {
          'name': tr('Outside Ethiopia?'),
          'desc': tr('Find a free, confidential helpline in your country.'),
          'action_type': 'url',
          'action_target': 'https://findahelpline.com',
          'badge': tr('Worldwide'),
          'icon': 'public_rounded',
        },
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final plan = ref.watch(safetyPlanProvider);
    final person = plan.people.isEmpty ? null : plan.people.first;

    return FriendPageScaffold(
      eyebrow: s.crisis,
      title: s.notAlone,
      showBack: true,
      subtitle: s.someoneCanTalkNow,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmergencyCard(
            onCall: (number) => _handleAction(context, {'action_type': 'call', 'action_target': number}),
          ),
          const SizedBox(height: 12),
          _HelpRequestCard(),
          const SizedBox(height: FriendLayout.sectionGap),
          FriendSectionLabel(tr('Other ways to get support')),
          FriendListGroup(
            children: [
              FriendMenuTile(
                icon: Icons.person_search_outlined,
                title: tr('Find someone to talk to'),
                subtitle: tr('See who has open times today'),
                onTap: () => context.go(AppRoutes.home),
              ),
              if (person != null)
                FriendMenuTile(
                  icon: Icons.call_outlined,
                  title: person.name,
                  subtitle: person.phone.isNotEmpty ? '${s.trustedContact} · ${person.phone}' : s.trustedContact,
                  onTap: person.phone.isNotEmpty
                      ? () => _handleAction(context, {'action_type': 'call', 'action_target': person.phone})
                      : () => context.push(AppRoutes.safetyPlan),
                )
              else
                FriendMenuTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: tr('Add someone you trust'),
                  subtitle: tr('So their number is one tap away when you need it'),
                  onTap: () => context.push(AppRoutes.safetyPlan),
                ),
              FriendMenuTile(
                icon: Icons.air_rounded,
                title: s.breatheWithMe,
                subtitle: s.guidedGrounding,
                onTap: () => BoxBreathingDialog.show(context),
              ),
              FriendMenuTile(
                icon: Icons.shield_outlined,
                title: s.mySafetyPlan,
                subtitle: s.safetyPlanStepsComplete(plan.stepsDone, 4),
                onTap: () => context.push(AppRoutes.safetyPlan),
              ),
            ],
          ),
          const SizedBox(height: FriendLayout.sectionGap),
          for (final res in _resources) ...[
            _CrisisResourceCard(resource: res, onTap: () => _handleAction(context, res)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// The first thing on the screen: the two Ethiopian emergency numbers.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onCall});

  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button(String label, String number) => Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FriendColors.error, minimumSize: const Size(0, 56)),
            onPressed: () => onCall(number),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                Text(number, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontFeatures: friendTabular)),
              ],
            ),
          ),
        );
    return CandyCard(
      tint: FriendColors.error,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('In danger right now?'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            tr('If you might hurt yourself or someone else, call now or go to the nearest hospital.'),
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.onErrorContainer),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              button(tr('Ambulance'), '907'),
              const SizedBox(width: 10),
              button(tr('Police'), '991'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrisisResourceCard extends StatelessWidget {
  const _CrisisResourceCard({required this.resource, required this.onTap});
  final Map<String, dynamic> resource;
  final VoidCallback onTap;

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'phone_in_talk_rounded':
        return Icons.phone_in_talk_rounded;
      case 'chat_bubble_outline_rounded':
        return Icons.chat_bubble_outline_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = resource['name'] as String? ?? '';
    final desc = resource['desc'] as String? ?? '';
    final badge = resource['badge'] as String? ?? '';
    final icon = _getIcon(resource['icon'] as String?);
    final type = resource['action_type'] as String? ?? 'call';

    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          FriendIconTile(icon: icon, color: FriendColors.error, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (badge.isNotEmpty)
                      FriendStatusChip(label: badge, color: FriendColors.error),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: Icon(
              type == 'call'
                  ? Icons.call_rounded
                  : (type == 'sms'
                      ? Icons.message_rounded
                      : Icons.open_in_new_rounded),
              color: FriendColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ask our team to reach out", or the status of a request already sent.
class _HelpRequestCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final alert = ref.watch(helpRequestProvider).valueOrNull;
    final state = alert?['state'] as String?;
    final active = state == 'waiting' || state == 'in_progress';
    final theme = Theme.of(context);

    return CandyCard(
      
      onTap: () => showHelpRequestSheet(context, ref),
      child: Row(
        children: [
          Icon(active ? Icons.mark_chat_read_rounded : Icons.support_agent_rounded, color: FriendColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !active
                      ? s.t('Ask our team to reach out', 'ቡድናችን እንዲያገኝዎት ይጠይቁ')
                      : state == 'in_progress'
                          ? s.t('Our team is contacting you', 'ቡድናችን እያገኘዎት ነው')
                          : s.t('Our team has been told', 'ለቡድናችን ተነግሯል'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? s.t('Keep your phone near you. Tap to add details.', 'ስልክዎን አጠገብዎ ያድርጉ። ተጨማሪ ለመንገር ይንኩ።')
                      : s.t('A real person from Akilil will call or message you', 'ከአኪሊል አንድ ሰው ይደውልልዎታል ወይም መልዕክት ይልክልዎታል'),
                  style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
