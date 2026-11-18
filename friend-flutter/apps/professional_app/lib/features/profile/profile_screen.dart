import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../l10n/language.dart';
import '../studio/studio_screens.dart';

import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull ?? const <String, dynamic>{};
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final status = profile['verification_status'];

    Future<void> signOut() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Sign out?')),
          content: Text(tr('You will need your email and password to sign back in.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('Log out')),
            ),
          ],
        ),
      );
      if (ok == true) await ref.read(authControllerProvider).logout();
    }

    Widget group(String label, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
              ),
              FriendListGroup(children: children),
            ],
          ),
        );

    return Material(
      color: FriendColors.background,
      child: SafeArea(
        bottom: false,
        child: FriendContentWidth(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 24, FriendLayout.horizontal, 40),
            children: [
              Row(
                children: [
                  FriendAvatar(initials: personInitial(user?.name, 'P'), size: 64, verified: status == 'approved'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(user?.name ?? '', style: theme.textTheme.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              if (status != null && status != 'approved') ...[
                const SizedBox(height: 16),
                CandyCard(
                  tint: FriendColors.warning,
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: FriendColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('Under review — clients cannot book you yet'),
                          style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              group(tr('Your practice'), [
                FriendMenuTile(icon: Icons.people_outline_rounded, title: tr('Clients'), onTap: () => context.go('/clients')),
                FriendMenuTile(
                  icon: Icons.edit_outlined,
                  title: tr('Practice profile'),
                  subtitle: tr('Bio, price, accepting clients'),
                  onTap: () => context.push('/care-settings'),
                ),
                if (profile['is_chef'] == true)
                  FriendMenuTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: tr('My recipes'),
                    subtitle: tr('Required for every cooking session'),
                    onTap: () => context.push('/recipes'),
                  ),
                if (profile['can_go_live'] == true)
                  FriendMenuTile(
                    icon: Icons.sensors_rounded,
                    title: tr('Go live'),
                    subtitle: tr('Broadcast to many, receive gifts'),
                    onTap: () => context.push('/live'),
                  ),
                FriendMenuTile(
                  icon: Icons.payments_outlined,
                  title: tr('Earnings & payouts'),
                  subtitle: tr('What you earned and withdrawals'),
                  onTap: () => context.go('/earnings'),
                ),
              ]),
              group(tr('Account'), [
                FriendMenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: tr('Two-factor authentication'),
                  subtitle: user?.totpConfirmed == true ? tr('Enabled') : tr('Recommended'),
                  onTap: () => context.go('/2fa-setup'),
                ),
                FriendMenuTile(icon: Icons.translate_rounded, title: tr('Language'), trailing: const ProLanguageSwitch()),
                FriendMenuTile(
                  icon: Icons.mail_outline_rounded,
                  title: tr('Support'),
                  subtitle: 'help@akilil.app',
                  onTap: () => launchUrl(Uri.parse('mailto:help@akilil.app')),
                ),
              ]),
              FriendListGroup(
                children: [FriendMenuTile(icon: Icons.logout_rounded, title: tr('Log out'), destructive: true, onTap: signOut)],
              ),
              const SizedBox(height: 24),
              Center(child: Text(tr('Akilil Pro v1.0.0'), style: theme.textTheme.labelSmall)),
            ],
          ),
        ),
      ),
    );
  }
}
