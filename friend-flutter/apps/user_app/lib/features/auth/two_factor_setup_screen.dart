import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:core/core.dart';

import 'auth_controller.dart';
import '../brand/brand_assets.dart';

/// 2FA setup wizard for the user app. Mirrors the Filament admin flow
/// (Task 6): server gives us a TOTP secret + otpauth URL, we render
/// a QR code + the secret in plain text, the user scans with their
/// authenticator app, then enters a 6-digit code to confirm.
///
/// After confirmation the auth controller refreshes `/me`; the router
/// redirect takes them to home.
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  String? _secret;
  String? _otpauthUrl;
  String? _codeError;
  bool _busy = false;
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
      setState(() => _codeError = "Couldn't start 2FA setup. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_secret == null) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _codeError = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/auth/2fa/confirm', data: {
        'secret': _secret,
        'code': code,
      });
      setState(() {
        _recoveryCodes = ((res.data ?? const {})['recovery_codes'] as List?)
                ?.cast<String>() ??
            const [];
      });
      await ref.read(authControllerProvider).refreshMe();
      if (!mounted) return;
      if (_recoveryCodes.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _RecoveryCodesDialog(codes: _recoveryCodes),
        );
      }
    } on DioException {
      setState(() => _codeError = "That code didn't work. Try a fresh one.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_busy && _secret == null) {
      return const FriendPageScaffold(
        eyebrow: 'Security',
        title: 'Two-factor authentication',
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return FriendPageScaffold(
      eyebrow: 'Security',
      title: 'Secure your account',
      subtitle: 'Scan the QR code with your authenticator app, then enter the 6-digit code.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: BrandAssets.mark(size: 48)),
          const SizedBox(height: 16),
          if (_otpauthUrl != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(FriendRadii.medium),
                  border: Border.all(color: FriendColors.border),
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
            Text(
              'Or enter this secret manually:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _secret!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secret copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(FriendRadii.small),
                  border: Border.all(color: FriendColors.border),
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
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              counterText: '',
            ),
            onSubmitted: (_) => _confirm(),
          ),
          if (_codeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _codeError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FriendGlowButton(
            label: 'Confirm and enable',
            expanded: true,
            onPressed: _busy ? null : _confirm,
          ),
        ],
      ),
    );
  }
}

class _RecoveryCodesDialog extends StatelessWidget {
  const _RecoveryCodesDialog({required this.codes});
  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save your recovery codes'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "If you lose your phone, these are the only way back in. "
              "Save them somewhere safe — we can't show them again.",
            ),
            const SizedBox(height: 16),
            ...codes.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    c,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: codes.join('\n')));
            Navigator.of(context).pop();
          },
          child: const Text('Copy & close'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("I've saved them"),
        ),
      ],
    );
  }
}
