/// Akilil Platform — Shared Core
///
/// Barrel export for the `core` package. Both apps (`friend_user` and
/// `friend_professional`) import from a single place:
///
/// ```dart
/// import 'package:core/core.dart';
/// ```
///
/// Public surface intentionally small — feature-specific code lives in the
/// app's `lib/features/` folders (Tasks 7 & 8), not here.
library;

export 'src/theme/design_tokens.dart';
export 'src/theme/akilil_pillars.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/design_system_preview.dart';
export 'src/ui/candy_widgets.dart';
export 'src/ui/akilil_stitch_widgets.dart';
export 'src/ui/language_switch.dart';
export 'src/networking/api_client.dart';
export 'src/auth/token_storage.dart';
export 'src/jitsi/jitsi_session_view.dart';
export 'src/jitsi/session_call_chrome.dart';
export 'src/realtime/reverb_client.dart';
export 'src/util/money.dart';
export 'src/live/live_models.dart';
export 'src/live/live_feed_controller.dart';
export 'src/live/gift_effects.dart';
export 'src/live/live_room_view.dart';
export 'src/cooking/recipe_widgets.dart';
export 'src/auth/auth_flows.dart';
export 'src/util/i18n.dart';
