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
];
