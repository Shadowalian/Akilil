import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/design_tokens.dart';
import '../ui/akilil_stitch_widgets.dart';

/// How a room behaves. The server already bakes the matching Jitsi config
/// into the room URL (see `config/jitsi.php` → `modes`); the client adds
/// what only it can enforce: device permissions and its own chrome.
enum JitsiRoomMode {
  /// 1:1, couples or family session — everyone on camera.
  consult,

  /// Group therapy or a cooking class — tile view, members join muted.
  group,

  /// The person going live.
  broadcastHost,

  /// The audience of a live broadcast: watches and listens, never publishes.
  broadcastView;

  static JitsiRoomMode fromApi(String? value) => switch (value) {
        'group' => JitsiRoomMode.group,
        'broadcast_host' => JitsiRoomMode.broadcastHost,
        'broadcast_view' => JitsiRoomMode.broadcastView,
        _ => JitsiRoomMode.consult,
      };

  bool get canPublish => this != JitsiRoomMode.broadcastView;
  bool get isBroadcast => this == JitsiRoomMode.broadcastHost || this == JitsiRoomMode.broadcastView;
}

/// Akilil Meet host. Override per build:
/// `--dart-define=AKILIL_MEET_HOST=meet.akilil.app`.
const akililMeetHost = String.fromEnvironment('AKILIL_MEET_HOST', defaultValue: '13.140.131.249');

/// In-app Akilil Meet room (self-hosted).
///
/// Opens the session WebRTC UI inside the app with Akilil chrome —
/// no public Jitsi / ffmuc browser hand-off.
class JitsiSessionView extends StatefulWidget {
  const JitsiSessionView({
    super.key,
    required this.roomUrl,
    this.jwt,
    this.displayName,
    this.onLeave,
    this.onSos,
    this.mode = JitsiRoomMode.consult,
    this.showChrome = true,
    this.title,
    this.overlay,
  });

  final String roomUrl;
  final String? jwt;
  final String? displayName;
  final VoidCallback? onLeave;
  final VoidCallback? onSos;

  /// Room behaviour — see [JitsiRoomMode].
  final JitsiRoomMode mode;

  /// The default top bar (title, SOS, Leave). Turn off when [overlay]
  /// supplies its own chrome, as the live room does.
  final bool showChrome;

  /// Replaces the default "Live Sanctuary Chamber" title.
  final String? title;

  /// Drawn above the video and below the loading / error states: comments,
  /// gift effects, a recipe panel.
  final Widget? overlay;

  @override
  State<JitsiSessionView> createState() => _JitsiSessionViewState();
}

class _JitsiSessionViewState extends State<JitsiSessionView> {
  InAppWebViewController? _controller;
  // There is no in-app webview on web, so nothing will ever finish loading.
  var _loading = !kIsWeb;
  String? _error;
  var _left = false;

  static const _akililHosts = {
    '13.140.131.249',
    'meet.akilil.app',
  };

  bool _isAkililHost(String host) =>
      host == akililMeetHost || _akililHosts.contains(host) || host.contains('13.140.131.249');

  Uri _buildUri() {
    var rawUrl = widget.roomUrl.trim();

    // Legacy public-meet URLs → Akilil Meet on our VPS.
    rawUrl = rawUrl
        .replaceAll('https://meet.ffmuc.net', 'https://13.140.131.249:8443')
        .replaceAll('http://meet.ffmuc.net', 'https://13.140.131.249:8443')
        .replaceAll('https://meet.jit.si', 'https://13.140.131.249:8443')
        .replaceAll('http://meet.jit.si', 'https://13.140.131.249:8443')
        .replaceAll('http://13.140.131.249:18080', 'https://13.140.131.249:8443')
        .replaceAll('https://13.140.131.249:18080', 'https://13.140.131.249:8443')
        .replaceAll('http://127.0.0.1:18080', 'https://13.140.131.249:8443')
        .replaceAll('http://localhost:18080', 'https://13.140.131.249:8443');

    if (rawUrl.startsWith('http://13.140.131.249')) {
      rawUrl = rawUrl.replaceFirst('http://', 'https://');
      if (!rawUrl.contains(':8443') && !rawUrl.contains(':443')) {
        rawUrl = rawUrl.replaceFirst(
          'https://13.140.131.249',
          'https://13.140.131.249:8443',
        );
      }
    }

    final parsed = Uri.parse(rawUrl);
    final query = Map<String, String>.from(parsed.queryParameters);
    if (widget.jwt != null && widget.jwt!.isNotEmpty) {
      query['jwt'] = widget.jwt!;
    }

    var uri = parsed.replace(
      queryParameters: query.isEmpty ? null : query,
    );

    const joinFlags = <String>[
      'config.prejoinPageEnabled=false',
      'config.prejoinConfig.enabled=false',
      'config.enableLobby=false',
      'config.lobby.enabled=false',
      'config.requireDisplayName=false',
      'config.startWithAudioMuted=false',
      'config.startWithVideoMuted=false',
      'config.disableDeepLinking=true',
      'config.enableWelcomePage=false',
      'config.disableSelfView=false',
      'config.filmstrip.disableSelfView=false',
      'config.disableFilmstripAutohiding=true',
      'config.p2p.enabled=false',
      'config.subject="Akilil Meet"',
      'config.localSubject="Akilil Meet"',
      'interfaceConfig.APP_NAME="Akilil Meet"',
      'interfaceConfig.SHOW_JITSI_WATERMARK=false',
      'interfaceConfig.SHOW_WATERMARK_FOR_GUESTS=false',
      'interfaceConfig.SHOW_POWERED_BY=false',
      'interfaceConfig.MOBILE_APP_PROMO=false',
      'interfaceConfig.DEFAULT_LOGO_URL="images/akilil-logo.svg"',
    ];

    final existing = uri.fragment;
    final bits = <String>[
      if (existing.isNotEmpty) existing,
      ...joinFlags.where((f) => !existing.contains(f.split('=').first)),
    ];

    if (widget.displayName != null && widget.displayName!.isNotEmpty) {
      final safe = Uri.encodeComponent(widget.displayName!);
      bits.add('userInfo.displayName="$safe"');
    }

    return uri.replace(fragment: bits.join('&'));
  }

  void _signalLeave() {
    if (_left) return;
    _left = true;
    widget.onLeave?.call();
  }

  Future<void> _injectBrand() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.evaluateJavascript(source: r'''
        (function () {
          try { document.title = "Akilil Meet"; } catch (e) {}
          var style = document.getElementById("akilil-brand-hide");
          if (!style) {
            style = document.createElement("style");
            style.id = "akilil-brand-hide";
            style.textContent = `
              .watermark, .leftwatermark, .rightwatermark,
              .welcome-page-button, .deep-linking-mobile,
              [class*="watermark"], [class*="jitsi-icon"],
              .promo, .poweredby { display: none !important; }
            `;
            document.documentElement.appendChild(style);
          }
        })();
      ''');
    } catch (_) {}
  }

  /// Mode-specific tweaks applied inside the page once it has loaded.
  Future<void> _applyMode() async {
    final c = _controller;
    if (c == null) return;
    try {
      if (widget.mode == JitsiRoomMode.broadcastView) {
        // Hide every control and thumbnail: the audience sees only the host.
        await c.evaluateJavascript(source: r'''
          (function () {
            var style = document.getElementById("akilil-viewer");
            if (!style) {
              style = document.createElement("style");
              style.id = "akilil-viewer";
              style.textContent = `
                .new-toolbox, .toolbox-content, #new-toolbox,
                .filmstrip, .vertical-filmstrip, .horizontal-filmstrip,
                .subject, .details-container, #notifications-container,
                .tile-view-toggle, .atlaskit-portal-container { display: none !important; }
                #largeVideoContainer, #videospace { background: #000 !important; }
              `;
              document.documentElement.appendChild(style);
            }
          })();
        ''');
      } else if (widget.mode == JitsiRoomMode.broadcastHost) {
        // Best effort: switch on audio/video moderation so nobody in the
        // audience can unmute. Server-side enforcement is Jitsi visitors
        // mode — see jitsi/AKILIL.md.
        await c.evaluateJavascript(source: r'''
          (function () {
            if (window.__akililModeration) return;
            window.__akililModeration = true;
            var tries = 0;
            var timer = setInterval(function () {
              tries++;
              try {
                if (window.APP && APP.conference && APP.conference.isJoined && APP.conference.isJoined()) {
                  APP.store.dispatch({ type: "REQUEST_ENABLE_AUDIO_MODERATION" });
                  APP.store.dispatch({ type: "REQUEST_ENABLE_VIDEO_MODERATION" });
                  clearInterval(timer);
                }
              } catch (e) {}
              if (tries > 90) clearInterval(timer);
            }, 1000);
          })();
        ''');
      }
    } catch (_) {}
  }

  Future<void> _openExternalFallback() async {
    final uri = _buildUri();
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uri = _buildUri();

    return Material(
      color: FriendDarkColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!kIsWeb)
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                  source: '''
                    document.addEventListener("DOMContentLoaded", function () {
                      document.title = "Akilil Meet";
                    });
                  ''',
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
              ]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllow:
                    'camera; microphone; display-capture; autoplay; fullscreen',
                iframeAllowFullscreen: true,
                allowsBackForwardNavigationGestures: false,
                supportZoom: false,
                transparentBackground: true,
                // Self-signed Akilil Meet cert on the VPS.
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (_, __) {
                if (!mounted) return;
                setState(() {
                  _loading = true;
                  _error = null;
                });
              },
              onLoadStop: (_, __) async {
                await _injectBrand();
                await _applyMode();
                if (!mounted) return;
                setState(() => _loading = false);
              },
              onReceivedError: (_, __, error) {
                if (!mounted) return;
                setState(() {
                  _loading = false;
                  _error = error.description.isNotEmpty
                      ? error.description
                      : "Couldn't load Akilil Meet.";
                });
              },
              onPermissionRequest: (controller, request) async {
                // The audience of a broadcast never gets camera or microphone.
                return PermissionResponse(
                  resources: widget.mode.canPublish ? request.resources : const [],
                  action: widget.mode.canPublish
                      ? PermissionResponseAction.GRANT
                      : PermissionResponseAction.DENY,
                );
              },
              onReceivedServerTrustAuthRequest:
                  (controller, challenge) async {
                final host = challenge.protectionSpace.host;
                if (_isAkililHost(host)) {
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                }
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.CANCEL,
                );
              },
              shouldOverrideUrlLoading: (controller, action) async {
                final req = action.request.url;
                if (req == null) return NavigationActionPolicy.ALLOW;
                final host = req.host;
                if (_isAkililHost(host) || host.isEmpty) {
                  return NavigationActionPolicy.ALLOW;
                }
                // Block deep-links out to public meet / app stores.
                return NavigationActionPolicy.CANCEL;
              },
            )
          else
            const ColoredBox(color: Colors.black),

          if (widget.overlay != null) Positioned.fill(child: widget.overlay!),

          // Top Akilil Meet chrome — live sanctuary chamber
          if (widget.showChrome)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FriendColors.primary.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title ?? 'Live Sanctuary Chamber',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: FriendColors.secondaryFixedDim,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.mode == JitsiRoomMode.group ? 'PRIVATE GROUP' : 'PRIVATE SESSION',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSos != null)
                    FriendSosChip(
                      onTap: widget.onSos!,
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _signalLeave,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Leave'),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const ColoredBox(
              color: Color(0xCC0A1A20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: FriendColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Opening Akilil Meet…',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_error != null)
            ColoredBox(
              color: FriendDarkColors.background,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: FriendDarkColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          _controller?.reload();
                        },
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: _openExternalFallback,
                        child: const Text('Open in browser'),
                      ),
                      TextButton(
                        onPressed: _signalLeave,
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
