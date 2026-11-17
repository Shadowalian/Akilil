import 'dart:convert';

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
        'people': [for (final p in people) {'name': p.name, 'phone': p.phone}],
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

class SafetyPlanController extends StateNotifier<SafetyPlan> {
  SafetyPlanController() : super(const SafetyPlan()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) state = SafetyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupt entry is replaced by the next save.
    }
  }

  Future<void> update(SafetyPlan plan) async {
    state = plan;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(plan.toJson()));
    } catch (_) {}
  }
}

final safetyPlanProvider = StateNotifierProvider<SafetyPlanController, SafetyPlan>((ref) => SafetyPlanController());
