import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';
import 'app_lock_controller.dart';
import 'auth_controller.dart';

/// Full-screen clinical lock overlay shown whenever [appLockProvider] is `true`.
///
/// Designed to protect confidential patient records, SOAP notes, and video rooms.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
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
      setState(() => _error = 'Biometric check failed — enter your password.');
    }
    if (!ok && !lock.biometricsAvailable) {
      setState(() => _showPassword = true);
    }
  }

  Future<void> _submitPassword() async {
    final pwd = _passCtrl.text.trim();
    if (pwd.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
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
      if (mounted) setState(() => _error = 'Incorrect password. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.read(appLockProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final name = user?.name.trim().split(' ').first ?? 'Counselor';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: FriendAtmosphere()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: FriendColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: GoogleFonts.urbanist(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: FriendColors.primaryDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back, Dr. $name',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clinical workspace is locked for patient privacy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Biometric button (if available)
                    if (lock.biometricsAvailable && !_showPassword) ...[
                      ScaleTransition(
                        scale: _scale,
                        child: GestureDetector(
                          onTap: _busy ? null : _tryBiometrics,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2AADCF), FriendColors.primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: FriendColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: _busy
                                ? const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 52,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tap to scan Face ID or Fingerprint',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FriendColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextButton(
                        onPressed: () => setState(() {
                          _showPassword = true;
                          _error = null;
                        }),
                        child: Text(
                          'Use password instead',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FriendColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: FriendColors.primary,
                          ),
                        ),
                      ),
                    ],

                    // Password field fallback
                    if (_showPassword || !lock.biometricsAvailable) ...[
                      CandyCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter counselor password',
                              style: GoogleFonts.urbanist(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: FriendColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              autofocus: true,
                              onSubmitted: (_) => _submitPassword(),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
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
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FriendColors.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FriendGlowButton(
                              label: _busy ? 'Verifying…' : 'Unlock Workspace',
                              icon: Icons.lock_open_rounded,
                              expanded: true,
                              onPressed: _busy ? null : _submitPassword,
                            ),
                          ],
                        ),
                      ),
                      if (lock.biometricsAvailable) ...[
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _showPassword = false;
                            _error = null;
                          }),
                          icon: const Icon(Icons.fingerprint_rounded, size: 18),
                          label: Text(
                            'Use biometrics',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: () async {
                        await ref.read(authControllerProvider).logout();
                        if (!context.mounted) return;
                        ref.read(appLockProvider.notifier).unlockWithPassword();
                        context.go('/login');
                      },
                      child: Text(
                        'Sign in with a different counselor account',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FriendColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
