import 'package:friend_user/l10n/tr.dart';

import 'package:flutter/material.dart';

import 'package:core/core.dart';

/// Akilil brand mark — open spectrum arc + warm core (matches website SVG).
class BrandAssets {
  BrandAssets._();

  /// The Akilil mark: an open teal ring around a clay core.
  static Widget mark({double size = 56, Color color = FriendColors.aqua, Color core = FriendColors.accent}) {
    return AkililMark(size: size, ring: color, core: core);
  }

  /// Mark plus wordmark, for the top of auth screens.
  static Widget logo({double size = 26}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark(size: size),
        const SizedBox(width: 8),
        Text(
          tr('Akilil'),
          style: friendFont(
            fontWeight: FontWeight.w600,
            fontSize: size * 0.72,
            color: FriendColors.textPrimary,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

