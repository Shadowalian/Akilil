import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/language.dart';
import 'l10n/tr.dart';

import 'router.dart';
import 'features/auth/app_lock_controller.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/auth_controller.dart';

/// Top-level Akilil professional app widget.
///
/// Shares the design system, Amharic support and auto-lock security with the
/// client app.
class FriendProApp extends ConsumerWidget {
  const FriendProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(proLanguageProvider);
    trAmharic = lang == ProLanguage.am;
    coreTr = tr;
    coreLanguageCode = lang.code;

    return MaterialApp.router(
      title: tr('Akilil Pro'),
      debugShowCheckedModeBanner: false,
      theme: FriendAppTheme.light(),
      themeMode: ThemeMode.light,
      locale: lang.locale,
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Scaffolds are transparent by design; give every page the brand canvas.
      builder: (context, child) => ColoredBox(
        color: FriendColors.background,
        child: _AppLockWrapper(
          child: KeyedSubtree(key: ValueKey(lang), child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Observes lifecycle events to auto-lock the therapist app when it goes
/// to background, protecting confidential client PHI.
class _AppLockWrapper extends ConsumerStatefulWidget {
  const _AppLockWrapper({required this.child});
  final Widget child;

  @override
  ConsumerState<_AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<_AppLockWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isLoggedIn = ref.read(authControllerProvider).isAuthenticated == true;
    if (!isLoggedIn) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    final isLoggedIn = ref.watch(
      authControllerProvider.select((c) => c.isAuthenticated == true),
    );

    return Stack(
      children: [
        widget.child,
        if (isLocked && isLoggedIn)
          const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}