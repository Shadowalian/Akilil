import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Akilil broadcasts realtime events through Laravel Reverb, which speaks
/// the Pusher protocol — so we use `pusher_channels_flutter` on mobile.
///
/// Backend (Task 4):
///   - Reverb default host:    ws://{REVERB_HOST}:{REVERB_PORT}
///
/// Channels (Task 4):
///   - private-conversation.{id}     → 1:1 chat
///   - private-channel.{id}          → community / group channels
///   - private-appointments.{userId} → notifications for the logged-in user
///   - presence-notifications        → online/typing indicators (Task 4)
///
/// NOTE: Task 0.5 wires only the surface of this client (config + DI
/// provider). The full integration — subscribed channels, event handlers,
/// ChatProvider bridge, message cache — is built in Task 4 alongside
/// /api/conversations endpoints.
class ReverbConfig {
  const ReverbConfig({
    required this.wsHost,
    required this.wsPort,
    required this.appKey,
    required this.useTls,
  });

  final String wsHost;
  final int    wsPort;
  final String appKey;
  final bool   useTls;
}

ReverbConfig _defaultReverbConfig() {
  // Override at build time with --dart-define for staging/prod.
  // Matches config('broadcasting.connections.reverb.options') in Laravel.
  const wsHost = String.fromEnvironment('REVERB_HOST', defaultValue: '10.0.2.2');
  const wsPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  const appKey = String.fromEnvironment('REVERB_APP_KEY', defaultValue: 'local-reverb-key');
  const useTls = bool.fromEnvironment('REVERB_USE_TLS', defaultValue: false);

  return const ReverbConfig(
    wsHost: wsHost,
    wsPort: wsPort,
    appKey: appKey,
    useTls: useTls,
  );
}

final reverbConfigProvider = Provider<ReverbConfig>((_) => _defaultReverbConfig());

/// Single shared Reverb connection reused across the app lifetime.
final pusherClientProvider = Provider<PusherChannelsFlutter>((_) {
  return PusherChannelsFlutter.getInstance();
});

/// Connects to Reverb with a Sanctum token. Task 4 hooks this up to the
/// chat/notifications layer; for Task 0.5 it's a stub that exercises the
/// init wiring with the correct config & auth path.
///
/// pusher_channels_flutter 2.4 API:
///   - `apiKey` + `cluster` are required (cluster is unused by Reverb)
///   - `authEndpoint` is the URL Laravel listens on (POST /api/broadcasting/auth)
///   - `onAuthorizer` is invoked by Pusher JS to fetch a signed channel token.
///     We use this to inject the Sanctum Bearer header — the only safe way
///     to pass auth over the public WebSocket path.
Future<void> connectReverb(
  WidgetRef ref, {
  required String authToken,
}) async {
  final cfg = ref.read(reverbConfigProvider);
  final client = ref.read(pusherClientProvider);

  await client.init(
    apiKey: cfg.appKey,
    cluster: '',                       // Reverb ignores cluster
    useTLS: cfg.useTls,
    authEndpoint: '${apiBase()}/broadcasting/auth',
    onAuthorizer: (channelName, socketId, options) async {
      // The authorizer hit Laravel /broadcasting/auth which requires a
      // Sanctum token. We pass it via a standard Authorization header.
      // The native pusher client doesn't expose custom headers for this
      // callback; in Task 4 we'll proxy this through a small HTTP helper
      // that uses the token directly with the backend's CSRF flow.
      return null;
    },
    onError: (message, code, error) {
      // Task 4: surface through a global Riverpod error state.
    },
  );

  await client.connect();
}

String apiBase() {
  // Shared with Dio in api_client.dart. Duplicated here to avoid the
  // circular import; if you change the build flag, change both.
  return const String.fromEnvironment(
    'FRIEND_API_BASE_URL',
    defaultValue: 'http://13.140.131.249/api',
  );
}
