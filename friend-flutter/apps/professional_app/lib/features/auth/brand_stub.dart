import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// Pro-brand mark — same shape as the user-app brand but the inner
/// accent dot is larger to read as a "broadcast / host" presence.
/// Lives in this app (not the shared `core`) because the user app
/// has its own variant.
class ProBrand {
  ProBrand._();

  static Widget mark({double size = 56}) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: FriendGradients.spectrumHot,
          shape: BoxShape.circle,
          boxShadow: FriendElevation.glow,
        ),
        child: Center(
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FriendColors.spark, FriendColors.coral],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

Widget proBrandMark({double size = 56}) => ProBrand.mark(size: size);