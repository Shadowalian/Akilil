/// Formats minor units as money: `formatMoney(2500, 'ETB')` → `ETB 25`,
/// `formatMoney(255000, 'ETB')` → `2,550 ETB`.
/// "5,760 ETB" — amount first, grouped thousands, then the currency, the
/// way prices are written across both apps.
String formatMoney(num? cents, [String? currency]) {
  final value = (cents ?? 0) / 100;
  final whole = value.truncate().abs();
  final grouped = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final fraction = value == value.roundToDouble() ? '' : (value.abs() - whole).toStringAsFixed(2).substring(1);
  final text = '${value < 0 ? '-' : ''}$grouped$fraction';
  final code = (currency ?? '').trim();
  return code.isEmpty ? text : '$text $code';
}

/// Best human-readable message from an API error body.
String apiErrorMessage(Object? data, [String fallback = 'Something went wrong']) {
  if (data is Map) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return fallback;
}

/// The letter for an avatar: skips honorifics, so "Dr. Hanna Tesfaye" → "H".
String personInitial(String? name, [String fallback = '?']) {
  const titles = {'dr', 'dr.', 'chef', 'abba', 'prof', 'prof.', 'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.', 'sister', 'pastor', 'sheikh'};
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return fallback;
  final word = parts.firstWhere((p) => !titles.contains(p.toLowerCase()), orElse: () => parts.first);
  return word.substring(0, 1).toUpperCase();
}
