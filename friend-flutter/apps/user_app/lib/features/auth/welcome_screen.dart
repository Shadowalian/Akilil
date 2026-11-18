import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../l10n/tr.dart';
import '../../router.dart';

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: FriendGradients.sunrise,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: FriendContentWidth(
                maxWidth: 480,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AkililMark(size: 26, ring: Colors.white, core: FriendColors.accent),
                          const SizedBox(width: 8),
                          Text(tr('Akilil'), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                          const Spacer(),
                          const LanguageToggle(compact: true),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Semantics(
                        header: true,
                        child: Text(s.welcomeHeadline, style: theme.textTheme.displayMedium?.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.welcomeSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: FriendContentWidth(
                maxWidth: 480,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (pillar, title, subtitle) in pillars)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Row(
                            children: [
                              FriendIconTile(icon: pillar.icon, color: pillar.color, size: 44),
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
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: FriendColors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${s.welcomeVerifiedBold} ${s.welcomeVerifiedRest}',
                              style: theme.textTheme.bodySmall,
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
          ),
        ],
      ),
    );
  }
}
