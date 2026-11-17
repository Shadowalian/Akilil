import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// The Akilil mark (four petals) on a teal disc — the same logomark as the
/// client app, drawn in code so the Pro app needs no image asset.
class ProBrand {
  ProBrand._();

  static Widget mark({double size = 56}) {
    final petal = size * 0.17;
    final offset = size * 0.13;
    Widget dot(double dx, double dy) => Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: petal,
            height: petal,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FriendColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: FriendColors.primary.withValues(alpha: 0.28), blurRadius: size * 0.35, offset: Offset(0, size * 0.1)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [dot(0, -offset), dot(-offset, 0), dot(offset, 0), dot(0, offset)],
      ),
    );
  }
}

Widget proBrandMark({double size = 56}) => ProBrand.mark(size: size);
