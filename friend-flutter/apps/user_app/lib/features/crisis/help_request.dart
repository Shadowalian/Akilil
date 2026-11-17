import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';

/// The person's latest "please contact me" request, if any.
final helpRequestProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/crisis/alerts/latest');
  final alert = res.data?['alert'];
  return alert is Map ? Map<String, dynamic>.from(alert) : null;
});

/// Sends a request to Akilil's safety team. [reason] is `asked_for_help`
/// or `screener_self_harm`. Returns true when the team has been alerted.
Future<bool> sendHelpRequest(
  WidgetRef ref, {
  required String reason,
  String? phone,
  String contactMethod = 'call',
  String? message,
}) async {
  try {
    await ref.read(dioProvider).post('/crisis/alerts', data: {
      'reason': reason,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'contact_method': contactMethod,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    ref.invalidate(helpRequestProvider);
    return true;
  } on DioException {
    return false;
  }
}

/// "Ask our team to reach out" — phone, how to reach, optional words.
Future<void> showHelpRequestSheet(BuildContext context, WidgetRef ref, {String reason = 'asked_for_help'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FriendColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _HelpRequestSheet(reason: reason),
  );
}

class _HelpRequestSheet extends ConsumerStatefulWidget {
  const _HelpRequestSheet({required this.reason});
  final String reason;

  @override
  ConsumerState<_HelpRequestSheet> createState() => _HelpRequestSheetState();
}

class _HelpRequestSheetState extends ConsumerState<_HelpRequestSheet> {
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String _method = 'call';
  bool _busy = false;
  bool? _sent;

  @override
  void initState() {
    super.initState();
    ref.read(dioProvider).get<Map<String, dynamic>>('/me').then((r) {
      final me = (r.data?['data'] as Map?) ?? r.data;
      if (mounted && _phone.text.isEmpty) _phone.text = (me?['phone'] ?? '').toString();
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final ok = await sendHelpRequest(ref,
        reason: widget.reason, phone: _phone.text.trim(), contactMethod: _method, message: _message.text.trim());
    if (mounted) {
      setState(() {
        _busy = false;
        _sent = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sent == true) ...[
            const Icon(Icons.favorite_rounded, color: FriendColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(s.t('We have let our team know', 'ለቡድናችን አሳውቀናል'),
                textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              s.t(
                'Someone from Akilil will contact you as soon as they can. Keep your phone near you.\n\n'
                    'We are not an emergency service. If you might hurt yourself or are in danger right now, call 907 or go to the nearest hospital.',
                'ከአኪሊል አንድ ሰው በተቻለ ፍጥነት ያገኝዎታል። ስልክዎን አጠገብዎ ያድርጉ።\n\n'
                    'እኛ የአስቸኳይ ጊዜ አገልግሎት አይደለንም። ራስዎን ሊጎዱ ከሆነ ወይም አሁን አደጋ ላይ ከሆኑ 907 ይደውሉ ወይም በአቅራቢያዎ ወዳለ ሆስፒታል ይሂዱ።',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(s.t('Close', 'ዝጋ'))),
          ] else ...[
            Text(s.t('Ask our team to reach out', 'ቡድናችን እንዲያገኝዎት ይጠይቁ'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              s.t('A real person from Akilil will contact you. You do not have to explain anything now.',
                  'ከአኪሊል አንድ ሰው ያገኝዎታል። አሁን ምንም ማብራራት አይጠበቅብዎትም።'),
              style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: s.t('Phone number', 'የስልክ ቁጥር')),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.t('Call me', 'ይደውሉልኝ')),
                  showCheckmark: false,
                  selected: _method == 'call',
                  onSelected: (_) => setState(() => _method = 'call'),
                ),
                ChoiceChip(
                  label: Text(s.t('Message me', 'መልዕክት ይላኩልኝ')),
                  showCheckmark: false,
                  selected: _method == 'message',
                  onSelected: (_) => setState(() => _method = 'message'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.t('Anything you want us to know (optional)', 'ማወቅ ያለብን ነገር ካለ (ካልፈለጉ ይዝለሉት)'),
                alignLabelWithHint: true,
              ),
            ),
            if (_sent == false) ...[
              const SizedBox(height: 10),
              Text(
                s.t("That didn't go through. Please call 907 if you need help now.",
                    'መልዕክቱ አልደረሰም። አሁን እርዳታ ካስፈለገዎት 907 ይደውሉ።'),
                style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(_busy ? s.t('Sending…', 'በመላክ ላይ…') : s.t('Ask for a call', 'እንዲደውሉልኝ እጠይቃለሁ')),
            ),
          ],
        ],
      ),
    );
  }
}
