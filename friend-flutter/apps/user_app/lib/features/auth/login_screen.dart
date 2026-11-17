import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import 'app_lock_controller.dart';
import 'auth_controller.dart';
import 'auth_fields.dart';

/// Sign in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _bioBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If biometrics available, offer them immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryBiometric();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final lock = ref.read(appLockProvider.notifier);
    await lock.ensureInitialized();
    final hasSaved = await lock.hasSavedBiometricCredentials();
    if (!mounted) return;
    if (!lock.biometricsAvailable || !lock.biometricEnabled || !hasSaved) return;

    setState(() => _bioBusy = true);
    final ok = await lock.unlockWithBiometrics();
    if (!mounted) return;
    if (ok) {
      final creds = await lock.getSavedBiometricCredentials();
      if (creds != null) {
        try {
          await ref.read(authControllerProvider).login(
                email: creds.email,
                password: creds.password,
                askTwoFactorCode: () => showTwoFactorPrompt(context),
              );
          return;
        } catch (_) {
          if (mounted) {
            setState(() => _error = tr('Biometric session expired. Please sign in with password.'));
          }
        }
      }
    }
    if (mounted) setState(() => _bioBusy = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      await ref.read(authControllerProvider).login(
            email: email,
            password: password,
            askTwoFactorCode: () => showTwoFactorPrompt(context),
          );
      // Save credentials for future biometric 1-tap sign-ins
      await ref.read(appLockProvider.notifier).saveBiometricCredentials(
            email: email,
            password: password,
          );
      if (!mounted) return;
    } on DioException catch (e) {
      setState(() {
        _error = _readableError(e) ?? ref.read(stringsProvider).loginFailed;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _readableError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is Map && data['errors'] is Map) {
      final first = (data['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (e.type == DioExceptionType.connectionError) {
      return ref.read(stringsProvider).cantReach;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lock = ref.read(appLockProvider.notifier);

    return AuthScaffold(
      title: tr('Welcome back'),
      subtitle: tr('Sign in to see your sessions, messages and journal.'),
      footer: AuthSwitchLink(
        leading: s.dontHaveAccount,
        label: s.signUp,
        onTap: () => context.go(AppRoutes.register),
      ),
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: s.email,
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty || !v.contains('@')) return s.validEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AuthField(
                  label: s.password,
                  controller: _passCtrl,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  trailingLabel: GestureDetector(
                    onTap: () => showForgotPasswordFlow(
                      context,
                      ref.read(dioProvider),
                      initialEmail: _emailCtrl.text.trim(),
                    ),
                    child: Text(
                      s.forgotPassword,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: FriendColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  suffix: IconButton(
                    tooltip: _obscure ? tr('Show password') : tr('Hide password'),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? s.minPassword : null,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 20),
          AuthError(message: _error!),
        ],
        const SizedBox(height: 28),
        FriendGlowButton(
          label: s.logIn,
          busy: _busy,
          expanded: true,
          onPressed: _submit,
        ),
        if (lock.biometricsAvailable) ...[
          const SizedBox(height: 12),
          FriendGlowButton(
            label: tr('Sign in with Face ID / Fingerprint'),
            icon: Icons.fingerprint_rounded,
            secondary: true,
            expanded: true,
            busy: _bioBusy,
            onPressed: _tryBiometric,
          ),
        ],
      ],
    );
  }
}
