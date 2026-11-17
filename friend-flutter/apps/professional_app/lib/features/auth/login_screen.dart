import 'package:core/core.dart';
import '../shell/pro_stitch_chrome.dart';
import '../../l10n/language.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_controller.dart';
import 'auth_controller.dart';
import 'brand_stub.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _busy = false;
  bool _bioBusy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _tryBiometric(); });
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
    setState(() { _busy = true; _error = null; });
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    try {
      await ref.read(authControllerProvider).login(
            email: email,
            password: password,
            askTwoFactorCode: () => showTwoFactorPrompt(context),
          );
      await ref.read(appLockProvider.notifier).saveBiometricCredentials(
            email: email,
            password: password,
          );
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          _error =
              "Can't reach Akilil servers. Check your internet and try again.";
        } else if (e.response?.statusCode == 429) {
          _error = tr('Too many login attempts. Wait a minute and try again.');
        } else if (e.response?.data is Map) {
          _error = ((e.response!.data['message'] ?? tr('Login failed')) as String);
        } else {
          _error = tr('Login failed. Please try again.');
        }
      });
    } catch (e) {
      setState(() => _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : tr('Something went wrong. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lock = ref.read(appLockProvider.notifier);

    Widget label(String text, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textPrimary))),
              if (trailing != null) trailing,
            ],
          ),
        );

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 0),
              child: Row(
                children: [
                  proBrandMark(size: 26),
                  const SizedBox(width: 8),
                  const ProWordmark(),
                  const Spacer(),
                  const ProLanguageSwitch(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(header: true, child: Text(tr('Welcome back'), style: theme.textTheme.headlineLarge)),
                            const SizedBox(height: 8),
                            Text(
                              tr('Sign in to your Akilil Pro workspace'),
                              style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                            ),
                            const SizedBox(height: 32),
                            label(tr('Email')),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(hintText: 'you@example.com'),
                              validator: (v) => (v == null || !v.contains('@')) ? tr('Enter a valid email') : null,
                            ),
                            const SizedBox(height: 20),
                            label(
                              tr('Password'),
                              trailing: GestureDetector(
                                onTap: () => showForgotPasswordFlow(
                                  context,
                                  ref.read(dioProvider),
                                  initialEmail: _emailCtrl.text.trim(),
                                ),
                                child: Text(
                                  tr('Forgot password?'),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: FriendColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? tr('Show password') : tr('Hide password'),
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6) ? tr('At least 6 characters') : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: FriendColors.errorContainer,
                                  borderRadius: BorderRadius.circular(FriendRadii.medium),
                                ),
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.onErrorContainer),
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            FriendGlowButton(label: tr('Sign in'), busy: _busy, expanded: true, onPressed: _submit),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(tr('New to Akilil Pro?'), style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary)),
                  TextButton(onPressed: () => context.go('/register'), child: Text(tr('Apply to join'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
