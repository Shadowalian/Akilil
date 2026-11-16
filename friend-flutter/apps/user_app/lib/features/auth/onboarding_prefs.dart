import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDone = 'akilil_onboarding_done_v1';

final onboardingDoneProvider =
    StateNotifierProvider<OnboardingDoneNotifier, bool?>((ref) {
  return OnboardingDoneNotifier()..load();
});

class OnboardingDoneNotifier extends StateNotifier<bool?> {
  OnboardingDoneNotifier() : super(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    state = true;
  }
}
