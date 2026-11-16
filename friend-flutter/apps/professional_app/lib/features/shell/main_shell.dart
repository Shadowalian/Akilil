import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pro_stitch_chrome.dart';

/// Bottom-nav shell — Stitch glass dock + clinical canvas.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = <_NavTab>[
    _NavTab('/', 'Today'),
    _NavTab('/sessions', 'Sessions'),
    _NavTab('/groups', 'Groups'),
    _NavTab('/availability', 'Schedule'),
    _NavTab('/profile', 'Profile'),
  ];

  int _indexFor(String location) {
    if (location.startsWith('/sessions')) return 1;
    if (location.startsWith('/groups')) return 2;
    if (location.startsWith('/availability')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/clients')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    final hideNav = location.contains('/host') ||
        location.contains('/notes') ||
        location.contains('/room');
    return ColoredBox(
      color: FriendColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FriendAtmosphere(),
          Positioned.fill(child: child),
          if (!hideNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ProStitchBottomNav(
                selectedIndex: index,
                onSelected: (i) => context.go(_tabs[i].path),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab(this.path, this.label);
  final String path;
  final String label;
}
