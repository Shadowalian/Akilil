<?php

/**
 * Akilil Meet — self-hosted conference (branded; no public Jitsi site).
 */

return [

    'domain' => env('JITSI_DOMAIN', '13.140.131.249:8443'),
    'base_url' => env('JITSI_BASE_URL', 'https://13.140.131.249:8443'),

    'use_jwt' => (bool) env('JITSI_USE_JWT', false),

    'jwt' => [
        'app_id' => env('JITSI_JWT_APP_ID'),
        'secret' => env('JITSI_JWT_SECRET'),
        'audience' => env('JITSI_JWT_AUDIENCE', 'jitsi'),
        'subject' => env('JITSI_JWT_SUBJECT', '*'),
        'algorithm' => 'HS256',
        'lifetime_seconds' => 60 * 60 * 2,
    ],

    'room_prefix' => env('JITSI_ROOM_PREFIX', 'akilil-'),

    'webhook_secret' => env('JITSI_WEBHOOK_SECRET'),

    'allowed_iframe_origins' => array_filter(
        array_map('trim', explode(',', (string) env('JITSI_ALLOWED_IFRAME_ORIGINS', '')))
    ),

    /*
     * Passed as URL hash `#config.key=value&…` (prefix added in JitsiService).
     * Keep lobby/prejoin off so camera + mic start immediately.
     */
    'iframe_config' => [
        'prejoinPageEnabled' => false,
        'prejoinConfig.enabled' => false,
        'enableLobby' => false,
        'lobby.enabled' => false,
        'requireDisplayName' => false,
        'startWithAudioMuted' => false,
        'startWithVideoMuted' => false,
        'startAudioOnly' => false,
        'disableDeepLinking' => true,
        'enableWelcomePage' => false,
        'enableClosePage' => false,
        'disableInviteFunctions' => true,
        'hideConferenceSubject' => true,
        'enableInsecureRoomNameWarning' => false,
        'disableSelfView' => false,
        'filmstrip.disableSelfView' => false,
        'disableFilmstripAutohiding' => true,
        'subject' => 'Akilil Meet',
        'localSubject' => 'Akilil Meet',
        'toolbarButtons' => [
            'microphone',
            'camera',
            'desktop',
            'chat',
            'raisehand',
            'tileview',
            'hangup',
            'settings',
            'fullscreen',
        ],
        'p2p.enabled' => false,
        'interfaceConfig.APP_NAME' => 'Akilil Meet',
        'interfaceConfig.SHOW_JITSI_WATERMARK' => false,
        'interfaceConfig.SHOW_WATERMARK_FOR_GUESTS' => false,
        'interfaceConfig.SHOW_POWERED_BY' => false,
        'interfaceConfig.MOBILE_APP_PROMO' => false,
        'interfaceConfig.DEFAULT_LOGO_URL' => 'images/akilil-logo.svg',
    ],

    /*
     * Room modes. Each mode is a set of overrides layered on top of
     * `iframe_config`, so one Jitsi deployment serves very different rooms:
     *
     *   consult        1:1 / couples / family — everyone on camera.
     *   group          group therapy or a cooking class — tile view,
     *                  members join muted and raise a hand.
     *   broadcast_host the person going live — full controls.
     *   broadcast_view the audience — receive-only, no mic/camera buttons.
     *                  Chat, likes and gifts are drawn by the app on top.
     *
     * Viewer lock-down here is client configuration. For hard,
     * server-side receive-only at scale turn on Jitsi visitors
     * (see jitsi/AKILIL.md).
     */
    'modes' => [
        'consult' => [],

        'group' => [
            'startWithAudioMuted' => true,
            'startWithVideoMuted' => false,
            'startInTileView' => true,
            'toolbarButtons' => [
                'microphone', 'camera', 'chat', 'raisehand', 'tileview',
                'participants-pane', 'hangup', 'settings', 'fullscreen',
            ],
        ],

        'broadcast_host' => [
            'startWithAudioMuted' => false,
            'startWithVideoMuted' => false,
            'disableFilmstripAutohiding' => false,
            'filmstrip.disabled' => true,
            'toolbarButtons' => [
                'microphone', 'camera', 'desktop', 'participants-pane',
                'select-background', 'settings', 'hangup',
            ],
            'notifications' => [],
            'disableJoinLeaveSounds' => true,
        ],

        'broadcast_view' => [
            'startWithAudioMuted' => true,
            'startWithVideoMuted' => true,
            'disableInitialGUM' => true,
            'startSilent' => false,
            'filmstrip.disabled' => true,
            'disableFilmstripAutohiding' => false,
            'disableSelfView' => true,
            'filmstrip.disableSelfView' => true,
            'hideParticipantsStats' => true,
            'disableRemoteMute' => true,
            'remoteVideoMenu.disabled' => true,
            'disableProfile' => true,
            'toolbarButtons' => [],
            'notifications' => [],
            'disableJoinLeaveSounds' => true,
            'interfaceConfig.TOOLBAR_ALWAYS_VISIBLE' => false,
        ],
    ],
];
