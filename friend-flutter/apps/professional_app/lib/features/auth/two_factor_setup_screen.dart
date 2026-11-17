import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:core/core.dart';

import 'auth_controller.dart';
import 'brand_stub.dart';

/// Same wizard as the user app: scan QR, enter code, save recovery
/// codes. Kept here so the pro app can be tested in isolation.
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _S();
}

class _S extends ConsumerState<TwoFactorSetupScreen> {
  String? _secret;
  String? _otpauthUrl;
  bool _busy = false;
  String? _codeError;
  final _code = TextEditingController();
  List<String> _recoveryCodes = const [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/auth/2fa/setup');
      final data = res.data ?? const {};
      setState(() {
        _secret = data['secret'] as String?;
        _otpauthUrl = data['otpauth_url'] as String?;
      });
    } on DioException {
      setState(() => _codeError = "Couldn't start 2FA setup.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_secret == null) return;
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _codeError = tr('Enter the 6-digit code.'));
      return;
    }
    setState(() { _busy = true; _codeError = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/auth/2fa/confirm',
        data: {'secret': _secret, 'code': code},
      );
      setState(() {
        _recoveryCodes = ((res.data ?? const {})['recovery_codes'] as List?)
                ?.cast<String>() ?? const [];
      });
      await ref.read(authControllerProvider).refreshMe();
      if (!mounted) return;
      if (_recoveryCodes.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) => AlertDialog(
            title: Text(tr('Save your recovery codes')),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("If you lose your phone, these are the only way back in."),
                  const SizedBox(height: 16),
                  ..._recoveryCodes.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(c, style: const TextStyle(fontFamily: 'monospace')),
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _recoveryCodes.join('\n')));
                  Navigator.pop(dCtx);
                },
                child: Text(tr('Copy & close')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text("I've saved them"),
              ),
            ],
          ),
        );
      }
    } on DioException {
      setState(() => _codeError = "That code didn't work. Try a fresh one.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Two-factor authentication'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _busy && _secret == null
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        proBrandMark(size: 48),
                        const SizedBox(height: 16),
                        Text(tr('Secure your account'), style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          tr('Scan the QR code in Google Authenticator, 1Password, '
                          'or Authy, then enter the 6-digit code below.'),
                        ),
                        const SizedBox(height: 24),
                        if (_otpauthUrl != null)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: QrImageView(
                                data: _otpauthUrl!,
                                size: 200,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (_secret != null) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _secret!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('Secret copied'))),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: Text(
                                _secret!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: tr('6-digit code'),
                            counterText: '',
                          ),
                        ),
                        if (_codeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_codeError!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error)),
                          ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _confirm,
                          child: Text(tr('Confirm and enable')),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}