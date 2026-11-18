import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../router.dart';
import '../auth/app_lock_controller.dart';
import '../auth/auth_controller.dart';
import '../brand/brand_assets.dart';

/// Full-screen lock overlay shown whenever [appLockProvider] is `true`.
///
/// • Shows a biometric button prominently if biometrics are available.
/// • Falls back to a password field for non-biometric devices.
/// • "Sign in with a different account" logs out and goes to login.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final _passCtrl = TextEditingController();
  bool _showPassword = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    // Auto-prompt biometrics on show.
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _tryBiometrics(); });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    setState(() => _busy = true);
    final lock = ref.read(appLockProvider.notifier);
    final ok = await lock.unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && lock.biometricsAvailable) {
      // Show error only if biometrics are available but failed
      setState(() => _error = tr('Biometric check failed — use your password.'));
    }
    if (!ok && !lock.biometricsAvailable) {
      // Device has no biometrics → jump straight to password field
      setState(() => _showPassword = true);
    }
  }

  Future<void> _submitPassword() async {
    final pwd = _passCtrl.text.trim();
    if (pwd.length < 6) {
      setState(() => _error = tr('Password must be at least 6 characters.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(authControllerProvider).login(
            email: user?.email ?? '',
            password: pwd,
          );
      if (!mounted) return;
      ref.read(appLockProvider.notifier).unlockWithPassword();
    } catch (_) {
      if (mounted) setState(() => _error = tr('Incorrect password. Try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.read(appLockProvider.notifier);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final name = user?.name.trim().split(' ').first ?? '';
    final showPassword = _showPassword || !lock.biometricsAvailable;

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: BrandAssets.mark(size: 44)),
                  const SizedBox(height: 24),
                  Text(
                    name.isEmpty ? tr('Welcome back') : trx('Welcome back, $name', 'እንኳን ደህና ተመለሱ፣ $name'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr("Verify it's you to continue"),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  if (!showPassword) ...[
                    Center(
                      child: ScaleTransition(
                        scale: _scale,
                        child: Semantics(
                          button: true,
                          label: tr('Tap to use Face ID or Fingerprint'),
                          child: Material(
                            color: FriendColors.surface,
                            shape: const CircleBorder(side: BorderSide(color: FriendColors.border)),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _busy ? null : _tryBiometrics,
                              child: SizedBox(
                                width: 88,
                                height: 88,
                                child: _busy
                                    ? const Center(
                                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    : const Icon(Icons.fingerprint_rounded, size: 44, color: FriendColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('Tap to use Face ID or Fingerprint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(() {
                        _showPassword = true;
                        _error = null;
                      }),
                      child: Text(tr('Use password instead')),
                    ),
                  ] else ...[
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      autofocus: true,
                      onSubmitted: (_) => _submitPassword(),
                      decoration: InputDecoration(
                        labelText: tr('Enter your password'),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? tr('Show password') : tr('Hide password'),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.error)),
                    ],
                    const SizedBox(height: 16),
                    FriendGlowButton(label: tr('Unlock'), expanded: true, busy: _busy, onPressed: _submitPassword),
                    if (lock.biometricsAvailable) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _showPassword = false;
                          _error = null;
                        }),
                        icon: const Icon(Icons.fingerprint_rounded, size: 18),
                        label: Text(tr('Use biometrics')),
                      ),
                    ],
                  ],
                  const SizedBox(height: 40),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: FriendColors.textSecondary),
                    onPressed: () async {
                      await ref.read(authControllerProvider).logout();
                      if (!context.mounted) return;
                      ref.read(appLockProvider.notifier).unlockWithPassword();
                      context.go(AppRoutes.login);
                    },
                    child: Text(tr('Sign in with a different account')),
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
