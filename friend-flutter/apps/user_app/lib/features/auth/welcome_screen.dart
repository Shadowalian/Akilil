import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../l10n/tr.dart';
import '../../router.dart';
import '../brand/brand_assets.dart';

/// First screen. Says what Akilil is in one line, shows the three kinds of
/// people you can reach, and offers one clear way in.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);

    final pillars = [
      (AkililPillars.psychiatry, tr('Therapists and psychiatrists'), tr('Licensed, and checked by our team')),
      (AkililPillars.spiritualPsychiatry, tr('Faith-aware counsellors'), tr('Care that respects what you believe')),
      (AkililPillars.cooking, tr('Chefs'), tr('Cook along live, recipes sent ahead')),
    ];

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        child: FriendContentWidth(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    BrandAssets.logo(),
                    const Spacer(),
                    const LanguageToggle(compact: true),
                  ],
                ),
                const Spacer(flex: 2),
                Align(alignment: AlignmentDirectional.centerStart, child: BrandAssets.mark(size: 48)),
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(s.welcomeHeadline, style: theme.textTheme.displayMedium),
                ),
                const SizedBox(height: 12),
                Text(
                  s.welcomeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(color: FriendColors.textSecondary),
                ),
                const SizedBox(height: 32),
                for (final (pillar, title, subtitle) in pillars)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        FriendIconTile(icon: pillar.icon, color: pillar.color, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 1),
                              Text(subtitle, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(flex: 3),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: FriendColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.welcomeVerifiedBold} ${s.welcomeVerifiedRest}',
                        style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FriendGlowButton(
                  label: s.getStarted,
                  expanded: true,
                  onPressed: () => context.go(AppRoutes.onboarding),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: TextButton.styleFrom(foregroundColor: FriendColors.textPrimary),
                    child: Text(s.alreadyHaveAccountLink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
