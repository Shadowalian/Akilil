import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';

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

  /// The dock belongs to the five tab roots. Pushed pages (a profile, a
  /// booking, a recipe, a live room) own the bottom of the screen.
  static final _fullScreen = RegExp(
    r'^/(pros/|recipes/|live|family|wallet|groups/\d|groups/meetings|messages/\d|journal/|community/\d|worksheets/\d|settings|notifications|crisis|appointments/\d)',
  );

  bool _hideDock(String location) => _fullScreen.hasMatch(location);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    final hideDock = _hideDock(location);

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

    // Material ancestor: without it every Text in the shell falls back to
    // the debug style (yellow double underline).
    return Material(
      color: FriendColors.background,
      child: Column(
        children: [
          Expanded(child: SafeArea(bottom: false, child: child)),
          if (!hideDock)
            FriendFloatingDock(
              items: tabs,
              selectedIndex: index,
              onSelected: (i) => context.go(tabs[i].path),
            ),
        ],
      ),
    );
  }
}
