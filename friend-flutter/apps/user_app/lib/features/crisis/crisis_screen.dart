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
        SnackBar(content: Text('Contact: $target')),
      );
    }
  }

  /// Numbers that work in Ethiopia. Deliberately short: in a crisis, fewer
  /// choices is kinder. Review with a local clinical advisor before launch.
  static const _resources = <Map<String, dynamic>>[
    {
      'name': 'Ambulance',
      'desc': 'Medical emergency, overdose or serious injury.',
      'action_type': 'call',
      'action_target': '907',
      'badge': 'Call 907',
      'icon': 'phone_in_talk_rounded',
    },
    {
      'name': 'Police',
      'desc': 'If you or someone else is in immediate danger.',
      'action_type': 'call',
      'action_target': '991',
      'badge': 'Call 991',
      'icon': 'shield_rounded',
    },
    {
      'name': 'Outside Ethiopia?',
      'desc': 'Find a free, confidential helpline in your country.',
      'action_type': 'url',
      'action_target': 'https://findahelpline.com',
      'badge': 'Worldwide',
      'icon': 'public_rounded',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const resources = _resources;
    final s = ref.watch(stringsProvider);
    final plan = ref.watch(safetyPlanProvider);
    final person = plan.people.isEmpty ? null : plan.people.first;
    final planDone = plan.stepsDone;

    return FriendPageScaffold(
      eyebrow: s.crisis,
      title: s.notAlone,
      showBack: true,
      subtitle: s.someoneCanTalkNow,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryCtaCard(
            title: s.talkToListenerNow,
            subtitle: s.listenersAvailableFree,
            onTap: () => context.push(AppRoutes.home),
          ),
          const SizedBox(height: 14),
          _HelpRequestCard(),
          const SizedBox(height: 14),
          _EmergencyCard(
            title: s.emergencyServices,
            number: s.localEmergencyNumber,
            callLabel: s.call,
            onCall: () => _handleAction(
              context,
              {'action_type': 'call', 'action_target': s.localEmergencyNumber},
            ),
          ),
          const SizedBox(height: 14),
          if (person != null)
            _ContactCard(
              name: person.name,
              role: s.trustedContact,
              phone: person.phone,
              onCall: person.phone.isNotEmpty
                  ? () => _handleAction(context, {'action_type': 'call', 'action_target': person.phone})
                  : null,
            )
          else
            _ToolkitCard(
              title: 'Add someone you trust',
              subtitle: 'So their number is one tap away when you need it',
              icon: Icons.person_add_alt_1_rounded,
              onTap: () => context.push(AppRoutes.safetyPlan),
            ),
          const SizedBox(height: 14),
          _ToolkitCard(
            title: s.breatheWithMe,
            subtitle: s.guidedGrounding,
            icon: Icons.air_rounded,
            onTap: () => BoxBreathingDialog.show(context),
          ),
          const SizedBox(height: 14),
          _ToolkitCard(
            title: s.mySafetyPlan,
            subtitle: s.safetyPlanStepsComplete(planDone, 4),
            icon: Icons.shield_outlined,
            onTap: () => context.push(AppRoutes.safetyPlan),
          ),
          const SizedBox(height: 28),
          Text(
            s.verifiedCrisisLifelines,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: FriendTypeScale.headlineSmall,
              fontWeight: FontWeight.w800,
              color: FriendColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final res in resources) ...[
            _CrisisResourceCard(
              resource: res,
              onTap: () => _handleAction(context, res),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PrimaryCtaCard extends StatelessWidget {
  const _PrimaryCtaCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendColors.primary,
      borderRadius: BorderRadius.circular(FriendRadii.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: FriendTypeScale.bodyLarge,
                        fontWeight: FontWeight.w800,
                        color: FriendColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: FriendTypeScale.bodySmall,
                        color: FriendColors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: FriendColors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.title,
    required this.number,
    required this.callLabel,
    required this.onCall,
  });

  final String title;
  final String number;
  final String callLabel;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FriendColors.errorContainer,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        border: Border.all(color: FriendColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.caption,
                    fontWeight: FontWeight.w700,
                    color: FriendColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: FriendTypeScale.headlineSmall,
                    fontWeight: FontWeight.w800,
                    color: FriendColors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onCall,
            style: FilledButton.styleFrom(
              backgroundColor: FriendColors.error,
              foregroundColor: FriendColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
            ),
            child: Text(
              callLabel,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.role,
    required this.phone,
    this.onCall,
  });

  final String name;
  final String role;
  final String? phone;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: FriendColors.primaryLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w800,
                color: FriendColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodySmall,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onCall != null)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, color: FriendColors.primary),
            ),
        ],
      ),
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  const _ToolkitCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FriendColors.apricot,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Icon(icon, color: FriendColors.accentDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodySmall,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: FriendColors.textMuted),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FriendColors.recessed,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Icon(icon, color: FriendColors.primaryDeep, size: 22),
          ),
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
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: FriendTypeScale.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: FriendColors.primaryLight,
                          borderRadius: BorderRadius.circular(FriendRadii.pill),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FriendColors.primaryDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: FriendTypeScale.bodySmall,
                    height: 1.35,
                    color: FriendColors.textSecondary,
                  ),
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
      tint: FriendColors.primary,
      accentStripe: true,
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
