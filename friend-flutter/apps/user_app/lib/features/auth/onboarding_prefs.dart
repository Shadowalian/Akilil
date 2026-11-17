import 'dart:convert';

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


const _kPendingIntake = 'akilil_pending_intake_v1';

/// Intake answers given before the account existed.
Future<void> savePendingIntake(Map<String, dynamic> intake) async {
  try {
    (await SharedPreferences.getInstance()).setString(_kPendingIntake, jsonEncode(intake));
  } catch (_) {}
}

/// Returns and clears the pending intake, if any.
Future<Map<String, dynamic>?> takePendingIntake() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingIntake);
    if (raw == null) return null;
    await prefs.remove(_kPendingIntake);
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
