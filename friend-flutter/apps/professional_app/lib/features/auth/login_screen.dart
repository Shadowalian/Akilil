import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
          _error = 'Too many login attempts. Wait a minute and try again.';
        } else if (e.response?.data is Map) {
          _error = ((e.response!.data['message'] ?? 'Login failed') as String);
        } else {
          _error = 'Login failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FriendAtmosphere(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        proBrandMark(size: 72),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome back',
                          style: GoogleFonts.urbanist(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: FriendColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your Akilil Pro workspace',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: FriendColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: GoogleFonts.urbanist(),
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.urbanist(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FriendColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: FriendColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(FriendRadii.pill),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  'Sign in with password',
                                  style: GoogleFonts.urbanist(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),

                        // ── Biometric quick-login ───────────────
                        Builder(builder: (context) {
                          final lock = ref.read(appLockProvider.notifier);
                          if (!lock.biometricsAvailable) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 18),
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
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2AADCF), FriendColors.primary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: FriendColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
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
                                          size: 32,
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

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => showForgotPasswordFlow(
                            context,
                            ref.read(dioProvider),
                            initialEmail: _emailCtrl.text.trim(),
                          ),
                          child: const Text('Forgot password?'),
                        ),
                        TextButton(
                          // go_router app: Navigator.pushNamed has no route table and threw.
                          onPressed: () => context.go('/register'),
                          child: Text(
                            'New here? Apply to join Akilil Pro',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                              color: FriendColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}