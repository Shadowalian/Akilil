import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../studio/studio_screens.dart';

import '../auth/auth_controller.dart';
import '../auth/brand_stub.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull ?? const <String, dynamic>{};
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                proBrandMark(size: 80),
                const SizedBox(height: 8),
                Text(user?.name ?? '', style: theme.textTheme.titleLarge),
                Text(user?.email ?? '',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Clients'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/clients'),
          ),
          if (profile['can_go_live'] == true)
          ListTile(
            leading: const Icon(Icons.sensors_rounded),
            title: const Text('Go live'),
            subtitle: const Text('Broadcast to many, receive gifts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live'),
          ),
          if (profile['is_chef'] == true)
          ListTile(
            leading: const Icon(Icons.restaurant_menu_rounded),
            title: const Text('My recipes'),
            subtitle: const Text('Required for every cooking session'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recipes'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Practice profile'),
            subtitle: const Text('Bio, price, accepting clients'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/care-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Two-factor authentication'),
            subtitle: Text(user?.totpConfirmed == true ? 'Enabled' : 'Recommended'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/2fa-setup'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Earnings & payouts'),
            subtitle: const Text('What you earned and withdrawals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/earnings'),
          ),
          ListTile(
            leading: const Icon(Icons.support_outlined),
            title: const Text('Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('help@akilil.app')),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: FriendColors.error),
              label: const Text('Log out', style: TextStyle(color: FriendColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FriendColors.error),
              ),
              onPressed: () => ref.read(authControllerProvider).logout(),
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('Akilil Pro v1.0.0',
                style: TextStyle(color: FriendColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}