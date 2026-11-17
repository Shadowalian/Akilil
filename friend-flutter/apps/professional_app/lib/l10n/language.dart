import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProLanguage {
  en,
  am;

  String get code => name;
  Locale get locale => Locale(code);

  static ProLanguage fromCode(String? code) => code == 'am' ? ProLanguage.am : ProLanguage.en;
}

const _prefsKey = 'akilil_pro_language';

class ProLanguageController extends StateNotifier<ProLanguage> {
  ProLanguageController() : super(ProLanguage.en) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ProLanguage.fromCode(prefs.getString(_prefsKey));
  }

  Future<void> set(ProLanguage language) async {
    if (state == language) return;
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

final proLanguageProvider =
    StateNotifierProvider<ProLanguageController, ProLanguage>((ref) => ProLanguageController());

/// EN / አማ switch wired to the Pro app's saved language.
class ProLanguageSwitch extends ConsumerWidget {
  const ProLanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(proLanguageProvider);
    return FriendLanguageSwitch(
      amharic: lang == ProLanguage.am,
      onChanged: (am) => ref.read(proLanguageProvider.notifier).set(am ? ProLanguage.am : ProLanguage.en),
    );
  }
}
