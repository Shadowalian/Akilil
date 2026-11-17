import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../router.dart';
import '../auth/auth_controller.dart';

/// Profile: who you are, then everything else grouped by purpose.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final name = user?.name.trim();

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
              child: Text(s.logOut),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(authControllerProvider).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }

    return FriendTabScaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 24, FriendLayout.horizontal, 40),
        children: [
          Row(
            children: [
              FriendAvatar(size: 64, initials: personInitial(name ?? '', 'A')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        name?.isNotEmpty == true ? name! : s.profile,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user?.email.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(user!.email, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _Group(
            label: tr('Your care'),
            children: [
              FriendMenuTile(icon: Icons.event_outlined, title: s.sessions, onTap: () => context.go(AppRoutes.appts)),
              FriendMenuTile(
                icon: Icons.family_restroom_rounded,
                title: tr('Family'),
                subtitle: tr('Children you book for, session invitations'),
                onTap: () => context.go(AppRoutes.family),
              ),
              FriendMenuTile(
                icon: Icons.shield_outlined,
                title: tr('Safety plan'),
                subtitle: tr('My personalised crisis action plan'),
                onTap: () => context.go(AppRoutes.safetyPlan),
              ),
              FriendMenuTile(
                icon: Icons.support_rounded,
                title: tr('Crisis resources'),
                subtitle: tr('Hotlines and immediate support'),
                onTap: () => context.go(AppRoutes.crisis),
              ),
            ],
          ),
          _Group(
            label: tr('Tools'),
            children: [
              FriendMenuTile(icon: Icons.menu_book_outlined, title: s.journal, subtitle: s.privateNotes, onTap: () => context.go(AppRoutes.journalList)),
              FriendMenuTile(icon: Icons.flag_outlined, title: s.goalsHabits, onTap: () => context.go(AppRoutes.goals)),
              FriendMenuTile(
                icon: Icons.edit_note_rounded,
                title: tr('Worksheets'),
                subtitle: tr('CBT, DBT & mindfulness exercises'),
                onTap: () => context.go(AppRoutes.worksheets),
              ),
              FriendMenuTile(
                icon: Icons.fact_check_outlined,
                title: tr('Check-ins'),
                subtitle: tr('PHQ-9 & GAD-7 self-checks'),
                onTap: () => context.go(AppRoutes.assessments),
              ),
            ],
          ),
          _Group(
            label: tr('Together'),
            children: [
              FriendMenuTile(
                icon: Icons.groups_2_outlined,
                title: tr('Group therapy'),
                subtitle: tr('Join open listening circles'),
                onTap: () => context.go(AppRoutes.groups),
              ),
              FriendMenuTile(
                icon: Icons.sensors_rounded,
                title: tr('Live'),
                subtitle: tr('Spiritual reflections and cook-alongs'),
                onTap: () => context.go(AppRoutes.live),
              ),
              FriendMenuTile(icon: Icons.forum_outlined, title: s.community, subtitle: s.circlesVents, onTap: () => context.go(AppRoutes.community)),
            ],
          ),
          _Group(
            label: s.account,
            children: [
              FriendMenuTile(icon: Icons.account_balance_wallet_outlined, title: s.wallet, subtitle: s.walletSubtitle, onTap: () => context.go(AppRoutes.wallet)),
              FriendMenuTile(
                icon: Icons.receipt_long_outlined,
                title: tr('Pricing & refunds'),
                subtitle: tr('How sessions, classes and gifts are charged'),
                onTap: () => context.go(AppRoutes.subscription),
              ),
              FriendMenuTile(
                icon: Icons.swap_horiz_rounded,
                title: tr('Switch professional'),
                subtitle: tr('Find a better match for your needs'),
                onTap: () => context.go(AppRoutes.switchTherapist),
              ),
              FriendMenuTile(
                icon: Icons.lock_outline_rounded,
                title: s.twoFactor,
                subtitle: user?.totpConfirmed == true ? s.enabled : s.recommended,
                onTap: () => context.go(AppRoutes.setup2fa),
              ),
              FriendMenuTile(
                icon: Icons.notifications_none_rounded,
                title: tr('Notifications'),
                onTap: () => context.go(AppRoutes.notifications),
              ),
              FriendMenuTile(
                icon: Icons.translate_rounded,
                title: s.language,
                trailing: const LanguageToggle(compact: true),
              ),
              FriendMenuTile(
                icon: Icons.settings_outlined,
                title: tr('Settings'),
                subtitle: tr('Privacy, preferences and more'),
                onTap: () => context.go(AppRoutes.settings),
              ),
            ],
          ),
          FriendListGroup(
            children: [
              FriendMenuTile(icon: Icons.logout_rounded, title: s.logOut, destructive: true, onTap: signOut),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
          ),
          FriendListGroup(children: children),
        ],
      ),
    );
  }
}
