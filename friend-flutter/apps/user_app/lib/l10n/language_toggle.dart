import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

import 'app_locale.dart';

/// Always-visible English ↔ Amharic switch (high contrast).
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeControllerProvider);
    final s = ref.watch(stringsProvider);

    final switcher = _LanguageSwitcher(
      selected: lang,
      onChanged: (next) {
        ref.read(localeControllerProvider.notifier).setLanguage(next);
      },
    );

    if (compact) return switcher;

    return CandyCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            color: FriendColors.primaryDeep,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.language,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          switcher,
        ],
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.selected,
    required this.onChanged,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: FriendColors.primary.withValues(alpha: 0.28),
      color: Colors.white,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          border: Border.all(color: FriendColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              selected: selected == AppLanguage.en,
              label: 'EN',
              onTap: () => onChanged(AppLanguage.en),
            ),
            _LangChip(
              selected: selected == AppLanguage.am,
              label: 'አማ',
              onTap: () => onChanged(AppLanguage.am),
              ethiopic: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.ethiopic = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final bool ethiopic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FriendColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: ethiopic ? 'NotoSansEthiopic' : null,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: selected ? Colors.white : FriendColors.primaryDeep,
            ),
          ),
        ),
      ),
    );
  }
}
