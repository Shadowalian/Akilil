import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'design_tokens.dart';

/// Static showcase of every design-system token and a few core
/// component states. Used by the User app's onboarding intro screen,
/// the Pro app's design-system reference page, and as a smoke test
/// for any future theme change.
///
/// Drop it into any screen:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const DesignSystemPreviewScreen(),
/// ));
/// ```
///
/// Renders: palette swatches, type ramp, radii, and a sample card +
/// buttons in both light and dark variants.
class DesignSystemPreviewScreen extends StatelessWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Static constants — pick the right class via isDark.
    final palette = isDark
        ? (background: FriendDarkColors.background,
           surface:    FriendDarkColors.surface,
           recessed:   FriendDarkColors.recessed,
           primary:    FriendDarkColors.primary,
           primaryLt:  FriendDarkColors.primaryLight,
           accent:     FriendDarkColors.accent,
           accentDp:   FriendDarkColors.accentDeep,
           textP:      FriendDarkColors.textPrimary,
           textS:      FriendDarkColors.textSecondary,
           border:     FriendDarkColors.border,
           error:      FriendDarkColors.error)
        : (background: FriendColors.background,
           surface:    FriendColors.surface,
           recessed:   FriendColors.recessed,
           primary:    FriendColors.primary,
           primaryLt:  FriendColors.primaryLight,
           accent:     FriendColors.accent,
           accentDp:   FriendColors.accentDeep,
           textP:      FriendColors.textPrimary,
           textS:      FriendColors.textSecondary,
           border:     FriendColors.border,
           error:      FriendColors.error);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Preview is read-only; the app-level theme switch lives
              // in the user/pro app's settings screen (Task 7/8).
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FriendRadii.medium),
          children: [
            _SectionTitle('Palette'),
            _ColorGrid(colors: {
              'background':     palette.background,
              'surface':        palette.surface,
              'recessed':       palette.recessed,
              'primary':        palette.primary,
              'primaryLight':   palette.primaryLt,
              'accent':         palette.accent,
              'accentDeep':     palette.accentDp,
              'textPrimary':    palette.textP,
              'textSecondary':  palette.textS,
              'border':         palette.border,
              'error':          palette.error,
            }),

            _SectionTitle('Type ramp'),
            _TypeRamp(isDark: isDark),

            _SectionTitle('Radii'),
            _RadiiRow(),

            _SectionTitle('Sample components'),
            const _SampleCard(),
            const SizedBox(height: FriendRadii.medium),
            _SampleButtons(isDark: isDark),
            const SizedBox(height: FriendRadii.medium),
            const _SampleInput(),
            const SizedBox(height: FriendRadii.medium),
            const _SampleChipRow(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors});
  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: colors.entries.map((e) => _ColorSwatch(name: e.key, color: e.value)).toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FriendRadii.small),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _readableOn(color),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _readableOn(color).withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Color _readableOn(Color bg) {
    // Quick contrast heuristic — surface dark → light text, else dark text.
    return bg.computeLuminance() > 0.5 ? FriendColors.textPrimary : Colors.white;
  }
}

class _TypeRamp extends StatelessWidget {
  const _TypeRamp({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget row(String label, TextStyle? style) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: t.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(child: Text('Akilil Platform', style: style)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('display-lg',  t.displayLarge),
          row('display-md',  t.displayMedium),
          row('headline-lg', t.headlineLarge),
          row('headline-md', t.headlineMedium),
          row('body-lg',     t.bodyLarge),
          row('body-md',     t.bodyMedium),
          row('body-sm',     t.bodySmall),
        ],
      ),
    );
  }
}

class _RadiiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget tile(String label, double r) => Expanded(
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: FriendColors.primary,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );

    return Row(children: [
      tile('12px', FriendRadii.small),
      const SizedBox(width: 12),
      tile('16px', FriendRadii.medium),
      const SizedBox(width: 12),
      tile('20px', FriendRadii.large),
      const SizedBox(width: 12),
      tile('pill', FriendRadii.pill),
    ]);
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FriendColors.primaryLight,
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                  child: const Icon(Icons.spa, color: FriendColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Maya Owens', style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'Spiritual counseling · 8 yrs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FriendColors.primary,
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Hold space for the parts of you that need rest. Together we find rhythm.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Book session')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () {}, child: const Text('View profile')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleButtons extends StatelessWidget {
  const _SampleButtons({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {},
            child: const Text('Primary'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Secondary'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FriendColors.accent,
              foregroundColor: FriendColors.onAccent,
            ),
            onPressed: () {},
            child: const Text('Accent'),
          ),
        ),
      ],
    );
  }
}

class _SampleInput extends StatelessWidget {
  const _SampleInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        prefixIcon: Icon(Icons.mail_outline),
      ),
    );
  }
}

class _SampleChipRow extends StatelessWidget {
  const _SampleChipRow();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, {bool selected = false}) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Therapy'),
        chip('Fitness', selected: true),
        chip('Cooking'),
        chip('Spiritual'),
        chip('Habits'),
      ],
    );
  }
}

/// Helper to push the preview screen from anywhere with a Navigator.
Future<void> openDesignSystemPreview(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DesignSystemPreviewScreen()),
  );
}

/// Convenience wrapper: applies either light or dark theme based on the
/// provided [mode]. Used by both apps' root MaterialApp:
///
/// ```dart
/// MaterialApp(
///   theme: FriendAppTheme.light(),
///   darkTheme: FriendAppTheme.dark(),
///   themeMode: ThemeMode.system,
///   home: const HomeScreen(),
/// );
/// ```
class FriendThemeSwitcher extends StatelessWidget {
  const FriendThemeSwitcher({
    super.key,
    required this.child,
    this.mode = ThemeMode.system,
  });

  final Widget child;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: switch (mode) {
        ThemeMode.dark  => FriendAppTheme.dark(),
        ThemeMode.light => FriendAppTheme.light(),
        ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? FriendAppTheme.dark()
            : FriendAppTheme.light(),
      },
      child: child,
    );
  }
}