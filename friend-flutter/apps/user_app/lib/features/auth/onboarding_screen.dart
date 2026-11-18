import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';

const _kSupportPaths = 'akilil_support_paths';

/// Step 1 of sign-up: which kinds of support the person is looking for.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _selected = <String>{};

  static const _order = ['psychiatry', 'spiritual-psychiatry', 'cooking'];

  void _toggle(String slug) {
    setState(() {
      if (!_selected.remove(slug)) _selected.add(slug);
    });
  }

  Future<void> _continue() async {
    if (_selected.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kSupportPaths, jsonEncode(_selected.toList()));
      } catch (_) {}
    }
    if (!mounted) return;
    context.go(AppRoutes.assessment);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final count = _selected.length;

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FriendContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    FriendBackButton(onPressed: () => context.go(AppRoutes.welcome)),
                    const SizedBox(width: 16),
                    const Expanded(child: OnboardingProgress(activeIndex: 0)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.assessment),
                      style: TextButton.styleFrom(foregroundColor: FriendColors.textSecondary),
                      child: Text(s.skip),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FriendContentWidth(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  children: [
                    Semantics(header: true, child: Text(s.chooseSupportTitle, style: theme.textTheme.headlineLarge)),
                    const SizedBox(height: 8),
                    Text(
                      s.chooseSupportSub,
                      style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    for (final slug in _order) ...[
                      _SupportCard(
                        pillar: AkililPillars.bySlug(slug)!,
                        selected: _selected.contains(slug),
                        title: s.pillarName(slug),
                        description: _descriptionFor(s, slug),
                        onTap: () => _toggle(slug),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            FriendStitchStickyBar(
              primaryLabel: s.continueWithSelected(count),
              primaryEnabled: count >= 1,
              onPrimary: _continue,
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
}

/// Segmented progress used across the sign-up steps.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.activeIndex, this.steps = 3});

  final int activeIndex;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: i <= activeIndex ? FriendColors.primary : FriendColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
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
    required this.pillar,
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final AkililPillar pillar;
  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(FriendRadii.card);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? FriendColors.primaryLight : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? FriendColors.primary : FriendColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendIconTile(icon: pillar.icon, color: pillar.color, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? FriendColors.primary : FriendColors.surface,
                    border: Border.all(
                      color: selected ? FriendColors.primary : FriendColors.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
