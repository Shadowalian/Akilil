import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_toggle.dart';
import '../auth/app_lock_controller.dart';
import '../messaging/care_team.dart';
import '../messaging/conversations_screen.dart';

/// Account settings: who you see, how you pay, your safety tools, privacy.
/// Everything here does something real.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _biometricLock;

  @override
  void initState() {
    super.initState();
    _biometricLock = ref.read(appLockProvider.notifier).biometricEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = ref.watch(careTeamProvider);

    Widget section(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            CandyCard(padding: EdgeInsets.zero, child: Column(children: children)),
          ],
        );
    const divider = Divider(height: 1, indent: 18, endIndent: 18);

    return FriendPageScaffold(
      eyebrow: 'Account',
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section('Your care team', [
            ...team.when(
              loading: () => const [Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator(minHeight: 2))],
              error: (_, _) => const [ListTile(title: Text("Couldn't load your care team"))],
              data: (list) => list.isEmpty
                  ? [
                      ListTile(
                        leading: const Icon(Icons.person_search_rounded, color: FriendColors.primary),
                        title: const Text('No one yet'),
                        subtitle: const Text('Find a professional who fits you'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/'),
                      ),
                    ]
                  : [
                      for (final (i, t) in list.indexed) ...[
                        if (i > 0) divider,
                        ListTile(
                          leading: FriendAvatar(initials: personInitial(t['name'] as String?), size: 40),
                          title: Text('${t['name']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Message',
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => openConversationWith(context, ref, t['user_id'] as int),
                              ),
                              IconButton(
                                tooltip: 'Book again',
                                icon: const Icon(Icons.event_repeat_rounded),
                                onPressed: () => context.push('/pros/${t['profile_id']}/book'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      divider,
                      FriendMenuTile(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Switch professional',
                        subtitle: 'Free, any time. They are not told why.',
                        onTap: () => context.push('/settings/switch-therapist'),
                      ),
                    ],
            ),
          ]),
          section('Payments', [
            FriendMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'Balance, top-ups and receipts',
              onTap: () => context.push('/wallet'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.receipt_long_outlined,
              title: 'Pricing & refunds',
              subtitle: 'How sessions, classes and gifts are charged',
              onTap: () => context.push('/settings/subscription'),
            ),
          ]),
          section('Care & safety', [
            FriendMenuTile(
              icon: Icons.emergency_outlined,
              title: 'Crisis support',
              subtitle: 'Emergency numbers and your safety plan',
              onTap: () => context.push('/crisis'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.edit_note_rounded,
              title: 'Worksheets',
              subtitle: 'Thought records and calming exercises',
              onTap: () => context.push('/worksheets'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.insights_rounded,
              title: 'Check-ins (PHQ-9 & GAD-7)',
              subtitle: 'Track low mood and anxiety over time',
              onTap: () => context.push('/assessments'),
            ),
          ]),
          section('Privacy & security', [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded, color: FriendColors.primary),
              title: const Text('App lock'),
              subtitle: const Text('Ask for your fingerprint or face to open Akilil'),
              value: _biometricLock,
              onChanged: (v) {
                setState(() => _biometricLock = v);
                ref.read(appLockProvider.notifier).setBiometricEnabled(enabled: v);
              },
            ),
            divider,
            FriendMenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'Two-step sign-in',
              subtitle: 'Add a code from an authenticator app',
              onTap: () => context.push('/2fa-setup'),
            ),
            divider,
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, color: FriendColors.primary),
                  SizedBox(width: 16),
                  Expanded(child: Text('Language')),
                  LanguageToggle(compact: true),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text(
            'Akilil is not an emergency service. If you are in danger, call 907 or 991, or go to the nearest hospital.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
