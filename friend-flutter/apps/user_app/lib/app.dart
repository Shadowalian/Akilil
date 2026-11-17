import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_locale.dart';
import 'l10n/tr.dart';
import 'router.dart';
import 'features/auth/app_lock_controller.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/auth_controller.dart';

/// Top-level Akilil user app.
///
/// Amharic is handled by our string table + bundled Noto Sans Ethiopic.
/// Material/Cupertino stay on English — Flutter has no `am` Material delegate.
class FriendApp extends ConsumerWidget {
  const FriendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(localeControllerProvider);
    trAmharic = lang == AppLanguage.am;
    coreTr = tr;
    coreLanguageCode = lang.code;
    final theme = FriendAppTheme.light();

    return MaterialApp.router(
      title: 'Akilil',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.light,
      // Flutter ships Amharic for its own widgets (date picker, dialogs).
      locale: lang.locale,
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => ColoredBox(
        color: FriendColors.background,
        // Re-key on language so every screen re-reads its copy.
        child: KeyedSubtree(
          key: ValueKey(lang),
          child: _AppLockWrapper(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Wraps the entire app. Observes lifecycle events to auto-lock the app when
/// it goes to background, and shows [AppLockScreen] as a full overlay when
/// the session is locked.
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
    if (!isLoggedIn) return; // don't lock on the auth screens

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Auto-lock the moment the user leaves the app
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    final isLoggedIn = ref.watch(authControllerProvider
        .select((c) => c.isAuthenticated == true));

    return Stack(
      children: [
        widget.child,
        // Show lock screen as a full overlay when locked AND logged in.
        if (isLocked && isLoggedIn)
          const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}
