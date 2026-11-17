import 'package:intl/intl.dart';

/// Pro app translations, keyed by the English text.
///
/// Wording is written for Ethiopian clinicians, spiritual counsellors and
/// chefs: polite form (እርስዎ), the words professionals actually use at work,
/// not word-for-word renderings of English UI copy.
bool trAmharic = false;

String tr(String en) => trAmharic ? (_am[en] ?? en) : en;

String trx(String en, String am) => trAmharic ? am : en;

String trDate(String pattern, DateTime date) {
  if (trAmharic) {
    try {
      return DateFormat(pattern, 'am').format(date);
    } catch (_) {}
  }
  return DateFormat(pattern).format(date);
}

const Map<String, String> _am = {
};
