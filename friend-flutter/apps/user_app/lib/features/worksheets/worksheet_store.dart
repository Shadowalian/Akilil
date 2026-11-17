import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Your worksheet answers, saved on this device only.
/// worksheet id → { field id → answer, '_completed_at' → ISO time }.
class WorksheetStore extends StateNotifier<Map<String, Map<String, String>>> {
  WorksheetStore() : super(const {}) {
    _load();
  }

  static const _key = 'akilil_worksheets_v1';

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = {
        for (final e in decoded.entries) e.key: Map<String, String>.from(e.value as Map),
      };
    } catch (_) {}
  }

  Future<void> save(String worksheetId, Map<String, String> answers) async {
    state = {
      ...state,
      worksheetId: {...answers, '_completed_at': DateTime.now().toIso8601String()},
    };
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(state));
    } catch (_) {}
  }
}

final worksheetStoreProvider =
    StateNotifierProvider<WorksheetStore, Map<String, Map<String, String>>>((ref) => WorksheetStore());
