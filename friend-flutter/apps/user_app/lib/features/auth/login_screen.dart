import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';
import '../../router.dart';
import '../brand/figma_assets.dart';
import 'app_lock_controller.dart';
import 'auth_controller.dart';
import 'auth_fields.dart';

/// Sign in — Freud aqua header, white pill fields, EN/AM toggle.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
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
            setState(() => _error = 'Biometric session expired. Please sign in with password.');
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
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FreudCurvedHeader(height: 210),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              s.signInToAkilil,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.2,
                                color: FriendColors.textPrimary,
                              ).copyWith(
                                fontFamilyFallback: const ['NotoSansEthiopic'],
                              ),
                            ),
                            const SizedBox(height: 28),
                            FreudField(
                              label: s.email,
                              controller: _emailCtrl,
                              hint: 'you@example.com',
                              icon: FigmaAssets.email(),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return s.validEmail;
                                }
                                if (!v.contains('@')) return s.validEmail;
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            FreudField(
                              label: s.password,
                              controller: _passCtrl,
                              hint: '••••••••',
                              icon: FigmaAssets.lock(),
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: FriendColors.textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? s.minPassword
                                  : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 20),
                              FreudAuthError(message: _error!),
                            ],
                            const SizedBox(height: 30),
                            FreudPillButton(
                              label: _busy ? '…' : s.logIn,
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 16),
                            // ── Biometric quick-login ───────────────
                            Builder(builder: (context) {
                              final lock = ref.read(appLockProvider.notifier);
                              if (!lock.biometricsAvailable) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'or',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 13,
                                            color: FriendColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _bioBusy ? null : _tryBiometric,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2AADCF), FriendColors.primary],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: FriendElevation.glowPressed,
                                      ),
                                      child: _bioBusy
                                          ? const Center(
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.fingerprint_rounded,
                                              size: 34,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in with Face ID / Fingerprint',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: FriendColors.textMuted,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 26),
                            FreudLink(
                              leading: s.dontHaveAccount,
                              label: s.signUp,
                              onTap: () => context.go(AppRoutes.register),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: GestureDetector(
                                onTap: () => showForgotPasswordFlow(
                                  context,
                                  ref.read(dioProvider),
                                  initialEmail: _emailCtrl.text.trim(),
                                ),
                                child: Text(
                                  s.forgotPassword,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: FriendColors.accent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: FriendColors.accent,
                                  ).copyWith(
                                    fontFamilyFallback: const [
                                      'NotoSansEthiopic'
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 16,
            child: Material(
              color: FriendColors.surface.withValues(alpha: 0.92),
              elevation: 1,
              shadowColor: FriendColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(FriendRadii.pill),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: LanguageToggle(compact: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
