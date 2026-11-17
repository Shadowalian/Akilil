import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// The Akilil mark, shared with the client app through core.
class ProBrand {
  ProBrand._();

  static Widget mark({double size = 56}) => AkililMark(size: size);
}

Widget proBrandMark({double size = 56}) => ProBrand.mark(size: size);
