import 'package:friend_user/l10n/tr.dart';
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
            CandyCard(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: children)),
          ],
        );
    const divider = Divider(height: 1, indent: 18, endIndent: 18);

    return FriendPageScaffold(
      eyebrow: tr('Account'),
      title: tr('Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section(tr('Your care team'), [
            ...team.when(
              loading: () => const [Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator(minHeight: 2))],
              error: (_, _) => const [ListTile(title: Text("Couldn't load your care team"))],
              data: (list) => list.isEmpty
                  ? [
                      ListTile(
                        leading: const Icon(Icons.person_search_rounded, color: FriendColors.primary),
                        title: Text(tr('No one yet')),
                        subtitle: Text(tr('Find a professional who fits you')),
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
                                tooltip: tr('Message'),
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => openConversationWith(context, ref, t['user_id'] as int),
                              ),
                              IconButton(
                                tooltip: tr('Book again'),
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
                        title: tr('Switch professional'),
                        subtitle: tr('Free, any time. They are not told why.'),
                        onTap: () => context.push('/settings/switch-therapist'),
                      ),
                    ],
            ),
          ]),
          section(tr('Payments'), [
            FriendMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: tr('Wallet'),
              subtitle: tr('Balance, top-ups and receipts'),
              onTap: () => context.push('/wallet'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.receipt_long_outlined,
              title: tr('Pricing & refunds'),
              subtitle: tr('How sessions, classes and gifts are charged'),
              onTap: () => context.push('/settings/subscription'),
            ),
          ]),
          section(tr('Care & safety'), [
            FriendMenuTile(
              icon: Icons.emergency_outlined,
              title: tr('Crisis support'),
              subtitle: tr('Emergency numbers and your safety plan'),
              onTap: () => context.push('/crisis'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.edit_note_rounded,
              title: tr('Worksheets'),
              subtitle: tr('Thought records and calming exercises'),
              onTap: () => context.push('/worksheets'),
            ),
            divider,
            FriendMenuTile(
              icon: Icons.insights_rounded,
              title: tr('Check-ins (PHQ-9 & GAD-7)'),
              subtitle: tr('Track low mood and anxiety over time'),
              onTap: () => context.push('/assessments'),
            ),
          ]),
          section(tr('Privacy & security'), [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded, color: FriendColors.primary),
              title: Text(tr('App lock')),
              subtitle: Text(tr('Ask for your fingerprint or face to open Akilil')),
              value: _biometricLock,
              onChanged: (v) {
                setState(() => _biometricLock = v);
                ref.read(appLockProvider.notifier).setBiometricEnabled(enabled: v);
              },
            ),
            divider,
            FriendMenuTile(
              icon: Icons.lock_outline_rounded,
              title: tr('Two-step sign-in'),
              subtitle: tr('Add a code from an authenticator app'),
              onTap: () => context.push('/2fa-setup'),
            ),
            divider,
            Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, color: FriendColors.primary),
                  SizedBox(width: 16),
                  Expanded(child: Text(tr('Language'))),
                  LanguageToggle(compact: true),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text(
            tr('Akilil is not an emergency service. If you are in danger, call 907 or 991, or go to the nearest hospital.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
