import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../auth/auth_controller.dart';
import '../auth/brand_stub.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ListTile(
            leading: const Icon(Icons.sensors_rounded),
            title: const Text('Go live'),
            subtitle: const Text('Broadcast to many, receive gifts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live'),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu_rounded),
            title: const Text('My recipes'),
            subtitle: const Text('Chefs: required for every cooking session'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recipes'),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_rounded),
            title: const Text('Who I work with'),
            subtitle: const Text('Couples, families, children, teens'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/care-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile editor — coming soon.')),
            ),
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
            title: const Text('Payout method'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add bank account — coming soon.')),
            ),
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