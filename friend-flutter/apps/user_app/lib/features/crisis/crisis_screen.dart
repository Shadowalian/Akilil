import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import '../core_data/seed_data.dart';
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

  int _safetyPlanProgress() {
    final p = SeedData.safetyPlan;
    var done = 0;
    if ((p['warning_signs'] as List).isNotEmpty) done++;
    if ((p['internal_coping'] as List).isNotEmpty) done++;
    if ((p['trusted_people'] as List).isNotEmpty) done++;
    return done;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = SeedData.crisisResources;
    final s = ref.watch(stringsProvider);
    final trusted =
        (SeedData.safetyPlan['trusted_people'] as List).cast<Map<String, String>>();
    final contact = trusted.isNotEmpty
        ? trusted.first
        : const <String, String>{'name': 'Selam', 'phone': ''};
    final planDone = _safetyPlanProgress();

    return FriendPageScaffold(
      eyebrow: s.crisis,
      title: s.notAlone,
      showBack: true,
      subtitle: s.someoneCanTalkNow,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          _PrimaryCtaCard(
            title: s.talkToListenerNow,
            subtitle: s.listenersAvailableFree,
            onTap: () => context.push(AppRoutes.home),
          ),
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
          _ContactCard(
            name: contact['name'] ?? 'Selam',
            role: s.trustedContact,
            phone: contact['phone'],
            onCall: contact['phone']?.isNotEmpty == true
                ? () => _handleAction(
                      context,
                      {
                        'action_type': 'call',
                        'action_target': contact['phone'],
                      },
                    )
                : null,
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
            subtitle: s.safetyPlanStepsComplete(planDone, 3),
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