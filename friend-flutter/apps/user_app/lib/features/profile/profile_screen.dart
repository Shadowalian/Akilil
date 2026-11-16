import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../router.dart';
import '../auth/auth_controller.dart';

/// Profile — identity block, real destinations, language, sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final s = ref.watch(stringsProvider);
    final name = user?.name.trim();
    final initial =
        (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'A';

    return FriendTabScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Column(
            children: [
              FriendAvatar(
                size: 92,
                initials: initial,
                verified: user?.totpConfirmed == true,
              ),
              const SizedBox(height: 16),
              Text(
                name?.isNotEmpty == true ? name! : s.profile,
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: FriendColors.textPrimary,
                ),
              ),
              if (user?.email.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // ── Wellness ────────────────────────────────────────────────
          _GroupLabel(s.wellness),
          CandyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FriendMenuTile(
                  icon: Icons.videocam_outlined,
                  title: s.sessions,
                  subtitle: s.upNext,
                  onTap: () => context.go(AppRoutes.appts),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.menu_book_outlined,
                  title: s.journal,
                  subtitle: s.privateNotes,
                  onTap: () => context.go(AppRoutes.journalList),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.flag_outlined,
                  title: s.goalsHabits,
                  onTap: () => context.go(AppRoutes.goals),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 12, 12, 12),
                  child: Row(
                    children: [
                      Icon(Icons.translate_rounded, size: 20, color: FriendColors.primary),
                      SizedBox(width: 14),
                      Expanded(child: Text('Language')),
                      LanguageToggle(compact: true),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Family',
                  subtitle: 'Children you book for, session invitations',
                  onTap: () => context.go(AppRoutes.family),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.sensors_rounded,
                  title: 'Live',
                  subtitle: 'Spiritual reflections and cook-alongs',
                  onTap: () => context.go(AppRoutes.live),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.groups_2_outlined,
                  title: 'Group therapy',
                  subtitle: 'Join open listening circles',
                  onTap: () => context.go(AppRoutes.groups),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.groups_outlined,
                  title: s.community,
                  subtitle: s.circlesVents,
                  onTap: () => context.go(AppRoutes.community),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Clinical Tools ──────────────────────────────────────────
          _GroupLabel('Clinical tools'),
          CandyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FriendMenuTile(
                  icon: Icons.description_outlined,
                  title: 'Worksheets',
                  subtitle: 'CBT, DBT & mindfulness exercises',
                  onTap: () => context.go(AppRoutes.worksheets),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Assessments',
                  subtitle: 'PHQ-9 & GAD-7 self-checks',
                  onTap: () => context.go(AppRoutes.assessments),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.emergency_outlined,
                  title: 'Crisis resources',
                  subtitle: 'Hotlines and immediate support',
                  onTap: () => context.go(AppRoutes.crisis),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.shield_outlined,
                  title: 'Safety plan',
                  subtitle: 'My personalised crisis action plan',
                  onTap: () => context.go(AppRoutes.safetyPlan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Care settings ───────────────────────────────────────────
          _GroupLabel('Care settings'),
          CandyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FriendMenuTile(
                  icon: Icons.star_outline_rounded,
                  title: 'My subscription',
                  subtitle: 'Plan, billing and premium features',
                  onTap: () => context.go(AppRoutes.subscription),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Switch therapist',
                  subtitle: 'Find a better match for your needs',
                  onTap: () => context.go(AppRoutes.switchTherapist),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Session reminders and updates',
                  onTap: () => context.go(AppRoutes.notifications),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Privacy, preferences and more',
                  onTap: () => context.go(AppRoutes.settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Language (always visible EN / AM) ───────────────────────
          _GroupLabel(s.language),
          const LanguageToggle(),
          const SizedBox(height: 26),

          // ── Account ─────────────────────────────────────────────────
          _GroupLabel(s.account),
          CandyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FriendMenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: s.wallet,
                  subtitle: s.walletSubtitle,
                  onTap: () => context.go(AppRoutes.wallet),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: s.twoFactor,
                  subtitle:
                      user?.totpConfirmed == true ? s.enabled : s.recommended,
                  onTap: () => context.go(AppRoutes.setup2fa),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
              side: BorderSide(
                color: FriendColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              s.logOut,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FriendColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: FriendColors.textMuted,
        ),
      ),
    );
  }
}
