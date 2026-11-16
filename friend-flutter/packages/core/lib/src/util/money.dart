/// Formats minor units as money: `formatMoney(2500, 'ETB')` → `ETB 25`,
/// `formatMoney(2550, 'USD')` → `USD 25.50`.
String formatMoney(num? cents, [String? currency]) {
  final value = (cents ?? 0) / 100;
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  final code = (currency ?? '').trim();
  return code.isEmpty ? text : '$code $text';
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
