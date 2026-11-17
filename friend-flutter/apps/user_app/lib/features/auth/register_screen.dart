import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../router.dart';
import 'auth_controller.dart';
import 'auth_fields.dart';

/// Create account.
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
  DateTime? _dob;
  String _careFor = 'self';
  bool _terms = false;
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
    final dob = _dob;
    if (dob == null) {
      setState(() => _error = tr('Please tell us your date of birth.'));
      return;
    }
    final now = DateTime.now();
    final age = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
    if (age < 18) {
      setState(() => _error =
          tr('Akilil accounts are for adults. Ask a parent or guardian to sign up and add you — they can book and pay for your sessions.'));
      return;
    }
    if (!_terms) {
      setState(() => _error = tr('Please accept the terms and privacy policy.'));
      return;
    }
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
            dateOfBirth: dob,
            seekingCareFor: _careFor,
          );
    } on DioException catch (e) {
      setState(() {
        _error = _readableError(e) ?? tr('Registration failed. Please try again.');
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
      return tr("We can't reach Akilil right now. Check your connection and try again.");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dob = _dob;

    return AuthScaffold(
      title: tr('Create your account'),
      subtitle: tr('Your answers are saved. One more step and you are in.'),
      footer: AuthSwitchLink(
        leading: tr('Already have an account? '),
        label: tr('Sign In'),
        onTap: () => context.go(AppRoutes.login),
      ),
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: tr('Full Name'),
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().length < 2) ? tr('Enter your name') : null,
                ),
                const SizedBox(height: 20),
                AuthField(
                  label: tr('Email Address'),
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || !v.contains('@')) ? tr('Enter a valid email') : null,
                ),
                const SizedBox(height: 20),
                AuthField(
                  label: tr('Password'),
                  controller: _pass,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  helper: tr('At least 8 characters, with upper and lower case and a number'),
                  suffix: IconButton(
                    tooltip: _obscure ? tr('Show password') : tr('Hide password'),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return tr('At least 8 characters');
                    if (!RegExp(r'[A-Z]').hasMatch(v) || !RegExp(r'[a-z]').hasMatch(v)) {
                      return tr('Use upper and lower case letters');
                    }
                    if (!RegExp(r'[0-9]').hasMatch(v)) return tr('Include at least one number');
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AuthField(
                  label: tr('Confirm Password'),
                  controller: _pass2,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => v == _pass.text ? null : tr("Passwords don't match"),
                ),
                const SizedBox(height: 20),
                AuthPickerField(
                  label: tr('Date of Birth'),
                  value: dob == null ? null : trDate('d MMMM y', dob),
                  placeholder: tr('Select your date of birth'),
                  helper: tr('Akilil accounts are for adults. Parents and guardians can add children after signing up.'),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dob ?? DateTime(now.year - 25),
                      firstDate: DateTime(1900),
                      lastDate: now,
                      helpText: tr('Your date of birth'),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    );
                    if (picked != null) setState(() => _dob = picked);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        AuthLabel(tr('Who are you looking for support for?')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in [
              ('self', tr('Myself')),
              ('couple', tr('Me & my partner')),
              ('child', tr('My child')),
              ('family', tr('My family')),
            ])
              ChoiceChip(
                label: Text(o.$2),
                selected: _careFor == o.$1,
                onSelected: (_) => setState(() => _careFor = o.$1),
              ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(FriendRadii.small),
          onTap: () => setState(() => _terms = !_terms),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('I am 18 or older and accept the Terms and Privacy Policy.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 20),
          AuthError(message: _error!),
        ],
        const SizedBox(height: 24),
        FriendGlowButton(label: tr('Create Account'), busy: _busy, expanded: true, onPressed: _submit),
      ],
    );
  }
}
