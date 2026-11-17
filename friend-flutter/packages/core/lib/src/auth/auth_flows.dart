import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../util/money.dart';

/// Asks for the 6-digit authenticator code (or a recovery code) during
/// sign-in. Returns null if the person cancels.
Future<String?> showTwoFactorPrompt(BuildContext context) {
  final code = TextEditingController();
  var recovery = false;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (d) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(recovery ? 'Use a recovery code' : 'Two-step sign-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recovery
                ? 'Enter one of the recovery codes you saved when you turned on two-step sign-in. Each works once.'
                : 'Open your authenticator app and enter the 6-digit code for Akilil.'),
            const SizedBox(height: 14),
            TextField(
              controller: code,
              autofocus: true,
              keyboardType: recovery ? TextInputType.text : TextInputType.number,
              textCapitalization: TextCapitalization.characters,
              maxLength: recovery ? 20 : 6,
              decoration: InputDecoration(labelText: recovery ? 'Recovery code' : '6-digit code', counterText: ''),
              onSubmitted: (v) => Navigator.pop(d, v.trim()),
            ),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => set(() {
                recovery = !recovery;
                code.clear();
              }),
              child: Text(recovery ? 'Use my authenticator app instead' : "I can't use my authenticator app"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, code.text.trim()), child: const Text('Verify')),
        ],
      ),
    ),
  );
}

/// Sends a challenge code (or recovery code) and returns the login payload.
Future<Map<String, dynamic>> completeTwoFactor(Dio dio, String challengeToken, String code) async {
  final isTotp = RegExp(r'^\d{6}$').hasMatch(code.replaceAll(' ', ''));
  final res = await dio.post<Map<String, dynamic>>('/auth/2fa/challenge', data: {
    'challenge_token': challengeToken,
    if (isTotp) 'code': code.replaceAll(' ', '') else 'recovery_code': code,
  });
  return res.data ?? const {};
}

/// Forgot password: email → 6-digit code → new password, in one sheet.
Future<void> showForgotPasswordFlow(BuildContext context, Dio dio, {String? initialEmail}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FriendColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ForgotPasswordSheet(dio: dio, initialEmail: initialEmail),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.dio, this.initialEmail});
  final Dio dio;
  final String? initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.type == DioExceptionType.connectionError
            ? "Can't reach Akilil. Check your connection."
            : apiErrorMessage(e.response?.data, 'Something went wrong. Try again.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        await widget.dio.post('/auth/forgot-password', data: {'email': _email.text.trim()});
        if (mounted) setState(() => _codeSent = true);
      });

  Future<void> _reset() => _run(() async {
        await widget.dio.post('/auth/reset-password', data: {
          'email': _email.text.trim(),
          'token': _code.text.trim(),
          'password': _pass.text,
          'password_confirmation': _pass.text,
        });
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed. Sign in with your new password.')),
        );
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_codeSent ? 'Check your email' : 'Reset your password', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            _codeSent
                ? 'If ${_email.text.trim()} has an account, we sent it a 6-digit code. It expires in 15 minutes.'
                : "Enter your account's email and we'll send you a code.",
            style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (!_codeSent)
            TextField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onSubmitted: (_) => _sendCode(),
            )
          else ...[
            TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'At least 8 characters, with upper and lower case and a number',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_busy ? 'Please wait…' : (_codeSent ? 'Change password' : 'Send code')),
          ),
          if (_codeSent)
            TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Send a new code')),
        ],
      ),
    );
  }
}
