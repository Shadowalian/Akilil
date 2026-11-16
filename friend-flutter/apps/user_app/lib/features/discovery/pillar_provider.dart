import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

/// Shared selected Akilil pillar for Discover (and deep-links from Today).
final discoverPillarProvider =
    StateProvider<String>((ref) => AkililPillars.defaultSlug);
