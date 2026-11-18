import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../ui/candy_widgets.dart';

/// Branded chrome for live video rooms (pro host + client).
class SessionCallChrome extends StatelessWidget {
  const SessionCallChrome({
    super.key,
    required this.child,
    required this.trailing,
    this.leading,
    this.title = 'Live session',
    this.subtitle,
  });

  final Widget child;
  final Widget? leading;
  final List<Widget> trailing;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FriendDarkColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
          // Soft brand wash at the top so chips sit on candy atmosphere.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FriendColors.primaryDeep.withValues(alpha: 0.55),
                    FriendColors.aqua.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: friendFont(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: friendFont(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionChromeChip extends StatelessWidget {
  const SessionChromeChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFFFB4B4) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.white.withValues(alpha: danger ? 0.16 : 0.18),
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FriendRadii.pill),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: friendFont(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading / connecting state before the room opens.
class SessionConnectingView extends StatelessWidget {
  const SessionConnectingView({super.key, this.message = 'Opening your room…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FriendAtmosphere(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: FriendColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: FriendColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: FriendColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: friendFont(
                      color: FriendColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
