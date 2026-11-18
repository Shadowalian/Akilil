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

    final switcher = FriendLanguageSwitch(
      amharic: lang == AppLanguage.am,
      onChanged: (am) {
        ref.read(localeControllerProvider.notifier).setLanguage(am ? AppLanguage.am : AppLanguage.en);
      },
    );

    if (compact) return switcher;

    return CandyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: FriendColors.textSecondary, size: 22),
          const SizedBox(width: 18),
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

