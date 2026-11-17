import 'package:friend_professional/l10n/tr.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pro_stitch_chrome.dart';

/// Tab shell: content above, docked tab bar below.
class MainShell extends StatelessWidget {
  MainShell({super.key, required this.child});
  final Widget child;

  static List<_NavTab> get _tabs => <_NavTab>[
    _NavTab('/', tr('Today')),
    _NavTab('/sessions', tr('Sessions')),
    _NavTab('/groups', tr('Groups')),
    _NavTab('/availability', tr('Schedule')),
    _NavTab('/profile', tr('Profile')),
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
    final hideNav = location.startsWith('/recipes') ||
        location.startsWith('/live') ||
        location.startsWith('/care-settings') ||
        location.contains('/host') ||
        location.contains('/notes') ||
        location.contains('/room');
    return Material(
      color: FriendColors.background,
      child: Column(
        children: [
          Expanded(child: child),
          if (!hideNav)
            ProStitchBottomNav(
              selectedIndex: index,
              onSelected: (i) => context.go(_tabs[i].path),
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
