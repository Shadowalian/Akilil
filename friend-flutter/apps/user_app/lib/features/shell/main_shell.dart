import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_toggle.dart';

/// Authenticated shell — cream canvas + floating capsule dock only.
/// No Scaffold bottom chrome (that was painting the full-width block).
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  int _indexFor(String location) {
    if (location.startsWith('/today')) return 0;
    if (location.startsWith('/appointments')) return 2;
    if (location.startsWith('/journal') || location.startsWith('/mood')) {
      return 3;
    }
    if (location.startsWith('/profile')) return 4;
    return 1;
  }

  bool _hideDock(String location) =>
      location.contains('/room') || RegExp(r'^/live/\d+').hasMatch(location) || location.contains('/meetings/');

  bool _hideLanguage(String location) => _hideDock(location);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    final hideDock = _hideDock(location);
    final hideLanguage = _hideLanguage(location);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    final tabs = <FriendDockItem>[
      FriendDockItem(
        path: '/today',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: s.home,
      ),
      FriendDockItem(
        path: '/',
        icon: Icons.travel_explore_outlined,
        selectedIcon: Icons.travel_explore_rounded,
        label: s.exploreNav,
      ),
      FriendDockItem(
        path: '/appointments',
        icon: Icons.videocam_outlined,
        selectedIcon: Icons.videocam_rounded,
        label: s.sessions,
      ),
      FriendDockItem(
        path: '/journal',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: s.journal,
      ),
      FriendDockItem(
        path: '/profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: s.profile,
      ),
    ];

    return ColoredBox(
      color: FriendColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FriendAtmosphere(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: hideDock ? 0 : FriendLayout.dockClearance,
                ),
                child: child,
              ),
            ),
          ),
          // Persistent language switch — visible on every tab.
          if (!hideLanguage)
            Positioned(
              top: topInset + 6,
              right: 16,
              child: const LanguageToggle(compact: true),
            ),
          if (!hideDock)
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomInset > 0 ? bottomInset : 14,
              child: FriendFloatingDock(
                items: tabs,
                selectedIndex: index,
                onSelected: (i) => context.go(tabs[i].path),
              ),
            ),
        ],
      ),
    );
  }
}
