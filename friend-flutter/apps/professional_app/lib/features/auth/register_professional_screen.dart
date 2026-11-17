import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'brand_stub.dart';

/// Pro registration. Same fields as the user-app register, with a
/// note that the user will be redirected into an onboarding wizard
/// after the first login.
class RegisterProfessionalScreen extends ConsumerStatefulWidget {
  const RegisterProfessionalScreen({super.key});

  @override
  ConsumerState<RegisterProfessionalScreen> createState() => _S();
}

class _S extends ConsumerState<RegisterProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  String? _pillar;
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
    if (_pillar == null) {
      setState(() => _error = 'Choose what you practise.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authControllerProvider).registerProfessional(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
            passwordConfirmation: _pass2.text,
            pillar: _pillar,
          );
    } on DioException catch (e) {
      setState(() {
        _error = apiErrorMessage(e.response?.data, 'Sign-up failed.');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent),
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
                    proBrandMark(size: 56),
                    const SizedBox(height: 16),
                    Text('Apply to be an Akilil Pro', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text("A few details. Our team checks every professional before clients can book them.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 24),
                    Text('What do you practise?', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    FriendPillarPicker(
                      selectedSlug: _pillar,
                      compact: true,
                      onSelected: (slug) => setState(() => _pillar = slug),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Your name'),
                      validator: (v) =>
                          (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) {
                        if (v == null || v.length < 8) return 'At least 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v) || !RegExp(r'[a-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Use upper and lower case letters and a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass2,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm password'),
                      validator: (v) => v == _pass.text ? null : 'Passwords don\'t match',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Create Pro account'),
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