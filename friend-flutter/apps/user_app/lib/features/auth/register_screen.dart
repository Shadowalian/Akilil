import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../../l10n/language_toggle.dart';
import '../../router.dart';
import '../brand/figma_assets.dart';
import 'auth_controller.dart';
import 'auth_fields.dart';

/// Create account — same Freud chrome as sign in, four fields, one CTA.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
            passwordConfirmation: _pass2.text,
          );
    } on DioException catch (e) {
      setState(() {
        _error = _readableError(e) ?? 'Registration failed. Please try again.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _readableError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['errors'] is Map) {
      final first = (data['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return "Can't reach Akilil servers. Is the API running on :8000?";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FreudCurvedHeader(height: 190),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Your Account',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.2,
                                color: FriendColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your answers are saved. One more step and you are in.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                color: FriendColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 26),
                            FreudField(
                              label: 'Full Name',
                              controller: _name,
                              hint: 'Selam Bekele',
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                size: 22,
                                color: FriendColors.wood,
                              ),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Enter your name'
                                      : null,
                            ),
                            const SizedBox(height: 22),
                            FreudField(
                              label: 'Email Address',
                              controller: _email,
                              hint: 'you@example.com',
                              icon: FigmaAssets.email(),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: 22),
                            FreudField(
                              label: 'Password',
                              controller: _pass,
                              hint: 'At least 8 characters',
                              icon: FigmaAssets.lock(),
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
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
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'At least 8 characters';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(v) ||
                                    !RegExp(r'[a-z]').hasMatch(v)) {
                                  return 'Use upper and lower case letters';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(v)) {
                                  return 'Include at least one number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            FreudField(
                              label: 'Confirm Password',
                              controller: _pass2,
                              hint: 'Repeat your password',
                              icon: FigmaAssets.lock(),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) => v == _pass.text
                                  ? null
                                  : "Passwords don't match",
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 20),
                              FreudAuthError(message: _error!),
                            ],
                            const SizedBox(height: 30),
                            FreudPillButton(
                              label: _busy ? '…' : 'Create Account',
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 26),
                            FreudLink(
                              leading: 'Already have an account? ',
                              label: 'Sign In',
                              onTap: () => context.go(AppRoutes.login),
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
