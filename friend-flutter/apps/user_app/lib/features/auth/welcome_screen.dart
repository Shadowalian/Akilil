import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../router.dart';

/// Welcome — matches mockup C01: full-bleed photo, white copy, sheet + amber CTA.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const _heroAsset = 'assets/figma/welcome_hero.jpg';
  static const _avatars = [
    'assets/figma/welcome_avatar_1.jpg',
    'assets/figma/welcome_avatar_2.jpg',
    'assets/figma/welcome_avatar_3.jpg',
    'assets/figma/welcome_avatar_4.jpg',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: FriendColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _heroAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.15),
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF1A1208),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.park_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'akilil',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const LanguageToggle(compact: true),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                        child: InkWell(
                          onTap: () => context.go(AppRoutes.login),
                          borderRadius:
                              BorderRadius.circular(FriendRadii.pill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              s.signIn,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 40, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.welcomeHeadline,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontFamilyFallback: ['NotoSansEthiopic'],
                          fontSize: 40,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.welcomeSubtitle,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontFamilyFallback: const ['NotoSansEthiopic'],
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  decoration: const BoxDecoration(
                    color: FriendColors.surfaceLowest,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(22, 22, 22, 18 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 92,
                            height: 36,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i < _avatars.length; i++)
                                  Positioned(
                                    left: i * 18.0,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: AssetImage(_avatars[i]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontFamilyFallback: ['NotoSansEthiopic'],
                                  fontSize: 14,
                                  height: 1.35,
                                  color: FriendColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: s.welcomeVerifiedBold,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${s.welcomeVerifiedRest}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: FriendColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: () => context.go(AppRoutes.onboarding),
                          style: FilledButton.styleFrom(
                            backgroundColor: FriendColors.accent,
                            foregroundColor: FriendColors.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(FriendRadii.medium),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          child: Text(s.getStarted),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          s.alreadyHaveAccountLink,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontFamilyFallback: ['NotoSansEthiopic'],
                            fontWeight: FontWeight.w500,
                            color: FriendColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
