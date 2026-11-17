import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../studio/studio_screens.dart';

import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull ?? const <String, dynamic>{};
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Profile'))),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                FriendAvatar(
                  initials: personInitial(user?.name, 'P'),
                  size: 80,
                  verified: profile['verification_status'] == 'approved',
                ),
                const SizedBox(height: 10),
                Text(user?.name ?? '', style: theme.textTheme.titleLarge),
                Text(user?.email ?? '',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                if (profile['verification_status'] != null && profile['verification_status'] != 'approved') ...[
                  const SizedBox(height: 10),
                  FriendStatusChip(
                    label: tr('Under review — clients cannot book you yet'),
                    color: FriendColors.accent,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(tr('Clients')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/clients'),
          ),
          if (profile['can_go_live'] == true)
          ListTile(
            leading: const Icon(Icons.sensors_rounded),
            title: Text(tr('Go live')),
            subtitle: Text(tr('Broadcast to many, receive gifts')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live'),
          ),
          if (profile['is_chef'] == true)
          ListTile(
            leading: const Icon(Icons.restaurant_menu_rounded),
            title: Text(tr('My recipes')),
            subtitle: Text(tr('Required for every cooking session')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recipes'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr('Practice profile')),
            subtitle: Text(tr('Bio, price, accepting clients')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/care-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(tr('Two-factor authentication')),
            subtitle: Text(user?.totpConfirmed == true ? 'Enabled' : tr('Recommended')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/2fa-setup'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(tr('Earnings & payouts')),
            subtitle: Text(tr('What you earned and withdrawals')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/earnings'),
          ),
          ListTile(
            leading: const Icon(Icons.support_outlined),
            title: Text(tr('Support')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('help@akilil.app'))),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: FriendColors.error),
              label: Text(tr('Log out'), style: TextStyle(color: FriendColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FriendColors.error),
              ),
              onPressed: () => ref.read(authControllerProvider).logout(),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(tr('Akilil Pro v1.0.0'),
                style: TextStyle(color: FriendColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}