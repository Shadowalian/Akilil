import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A person's safety plan. Kept on this device only: it is personal, it
/// must open with no network, and nobody else needs it.
class SafetyPlan {
  const SafetyPlan({
    this.warningSigns = const [],
    this.coping = const [],
    this.people = const [],
    this.environment = const [],
  });

  final List<String> warningSigns;
  final List<String> coping;
  final List<({String name, String phone})> people;
  final List<String> environment;

  int get stepsDone => [warningSigns, coping, people, environment].where((l) => l.isNotEmpty).length;

  SafetyPlan copyWith({
    List<String>? warningSigns,
    List<String>? coping,
    List<({String name, String phone})>? people,
    List<String>? environment,
  }) =>
      SafetyPlan(
        warningSigns: warningSigns ?? this.warningSigns,
        coping: coping ?? this.coping,
        people: people ?? this.people,
        environment: environment ?? this.environment,
      );

  Map<String, dynamic> toJson() => {
        'warning_signs': warningSigns,
        'coping': coping,
        'people': [
          for (final p in people) {'name': p.name, 'phone': p.phone},
        ],
        'environment': environment,
      };

  factory SafetyPlan.fromJson(Map<String, dynamic> j) => SafetyPlan(
        warningSigns: List<String>.from(j['warning_signs'] ?? const []),
        coping: List<String>.from(j['coping'] ?? const []),
        people: [
          for (final p in (j['people'] as List? ?? const []))
            (name: '${(p as Map)['name'] ?? ''}', phone: '${p['phone'] ?? ''}'),
        ],
        environment: List<String>.from(j['environment'] ?? const []),
      );
}

const _key = 'akilil_safety_plan_v1';

/// Saved to the account (so the person's professionals and the Akilil
/// safety team can read it) and cached on the phone (so it opens with no
/// signal, when it may matter most).
class SafetyPlanController extends StateNotifier<SafetyPlan> {
  SafetyPlanController(this._ref) : super(const SafetyPlan()) {
    _load();
  }

  final Ref _ref;
  bool _syncFailed = false;

  /// The last save only reached the phone.
  bool get syncFailed => _syncFailed;

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) state = SafetyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
    try {
      final res = await _ref.read(dioProvider).get<Map<String, dynamic>>('/me/safety-plan');
      final data = res.data;
      if (data != null && data['updated_at'] != null) {
        state = SafetyPlan.fromJson(data);
        await _cache(state);
      } else if (state.stepsDone > 0) {
        // Written on this phone before plans were saved to the account.
        await _push(state);
      }
    } catch (_) {
      // Offline: the cached copy is what we have.
    }
  }

  Future<void> update(SafetyPlan plan) async {
    state = plan;
    await _cache(plan);
    await _push(plan);
  }

  Future<void> _cache(SafetyPlan plan) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(plan.toJson()));
    } catch (_) {}
  }

  Future<void> _push(SafetyPlan plan) async {
    try {
      await _ref.read(dioProvider).put('/me/safety-plan', data: plan.toJson());
      _syncFailed = false;
    } catch (_) {
      _syncFailed = true;
    }
  }
}

final safetyPlanProvider = StateNotifierProvider<SafetyPlanController, SafetyPlan>((ref) => SafetyPlanController(ref));
