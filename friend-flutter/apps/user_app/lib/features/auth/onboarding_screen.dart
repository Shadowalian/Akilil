import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';

const _kSupportPaths = 'akilil_support_paths';

/// C02 — multi-select support pillars before clinical assessment.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _ethiopicFallback = ['NotoSansEthiopic'];

  final _selected = <String>{};

  static const _options = <_SupportOption>[
    _SupportOption(
      slug: 'spiritual-psychiatry',
      image: 'assets/figma/c02_spiritual.jpg',
      badgeKey: _BadgeKind.guides,
    ),
    _SupportOption(
      slug: 'cooking',
      image: 'assets/figma/c02_chef.jpg',
      badgeKey: _BadgeKind.chefs,
    ),
    _SupportOption(
      slug: 'psychiatry',
      image: 'assets/figma/c02_therapy.jpg',
      badgeKey: _BadgeKind.clinicians,
    ),
  ];

  TextStyle _geist({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Geist',
      fontFamilyFallback: _ethiopicFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  void _toggle(String slug) {
    setState(() {
      if (_selected.contains(slug)) {
        _selected.remove(slug);
      } else {
        _selected.add(slug);
      }
    });
  }

  Future<void> _persistSelection() async {
    if (_selected.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSupportPaths, jsonEncode(_selected.toList()));
    } catch (_) {}
  }

  Future<void> _continue() async {
    await _persistSelection();
    if (!mounted) return;
    context.go(AppRoutes.assessment);
  }

  void _skip() {
    context.go(AppRoutes.assessment);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final count = _selected.length;
    final canContinue = count >= 1;

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _BackCircle(onTap: () => context.go(AppRoutes.welcome)),
                  const SizedBox(width: 12),
                  Expanded(child: _OnboardingProgress(activeIndex: 0)),
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: FriendColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      s.skip,
                      style: _geist(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.chooseSupportTitle,
                    style: _geist(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.6,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.chooseSupportSub,
                    style: _geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                itemCount: _options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final opt = _options[i];
                  final selected = _selected.contains(opt.slug);
                  return _SupportCard(
                    option: opt,
                    selected: selected,
                    title: s.pillarName(opt.slug),
                    description: _descriptionFor(s, opt.slug),
                    badge: _badgeFor(s, opt.badgeKey),
                    onTap: () => _toggle(opt.slug),
                    geist: _geist,
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: FriendColors.surfaceLowest,
                border: Border(
                  top: BorderSide(color: FriendColors.border.withValues(alpha: 0.6)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: FriendColors.ink.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + bottomInset),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: canContinue ? _continue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: FriendColors.accent,
                      disabledBackgroundColor:
                          FriendColors.accent.withValues(alpha: 0.35),
                      foregroundColor: FriendColors.ink,
                      disabledForegroundColor:
                          FriendColors.ink.withValues(alpha: 0.45),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                    ),
                    child: Text(
                      s.continueWithSelected(count),
                      style: _geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: canContinue
                            ? FriendColors.ink
                            : FriendColors.ink.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _descriptionFor(S s, String slug) {
    switch (slug) {
      case 'spiritual-psychiatry':
        return s.spiritualCareDesc;
      case 'cooking':
        return s.chefSessionsDesc;
      case 'psychiatry':
        return s.psychiatryTherapyDesc;
      default:
        return '';
    }
  }

  String _badgeFor(S s, _BadgeKind kind) {
    switch (kind) {
      case _BadgeKind.guides:
        return s.guidesBadge;
      case _BadgeKind.chefs:
        return s.chefsBadge;
      case _BadgeKind.clinicians:
        return s.cliniciansBadge;
    }
  }
}

enum _BadgeKind { guides, chefs, clinicians }

class _SupportOption {
  const _SupportOption({
    required this.slug,
    required this.image,
    required this.badgeKey,
  });

  final String slug;
  final String image;
  final _BadgeKind badgeKey;
}

class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendColors.surfaceLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: FriendColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? FriendColors.ink
                    : FriendColors.border,
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.option,
    required this.selected,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
    required this.geist,
  });

  final _SupportOption option;
  final bool selected;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) geist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: FriendColors.surfaceLowest,
            borderRadius: BorderRadius.circular(FriendRadii.card),
            border: Border.all(
              color: selected ? FriendColors.accent : FriendColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: FriendColors.accent.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(FriendRadii.card - 1),
                    ),
                    child: SizedBox(
                      height: 148,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            option.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                              color: FriendColors.recessed,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: FriendColors.ink.withValues(alpha: 0.72),
                                borderRadius:
                                    BorderRadius.circular(FriendRadii.pill),
                              ),
                              child: Text(
                                badge,
                                style: geist(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: geist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: FriendColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: geist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: FriendColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _SelectionMark(selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? FriendColors.accent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? FriendColors.accent : FriendColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: FriendColors.ink.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: FriendColors.ink,
            )
          : null,
    );
  }
}