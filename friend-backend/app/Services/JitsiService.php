<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Support\Str;

/**
 * Jitsi service — issues signed room URLs and (optionally) JWTs for
 * Akilil video sessions.
 *
 * Dev: meet.jit.si (JWT off). Prod: self-host + JITSI_USE_JWT=true.
 */
class JitsiService
{
    public function generateRoom(Appointment $appointment): array
    {
        $random = Str::random(8);
        $roomName = sprintf(
            '%s%d-%s',
            config('jitsi.room_prefix'),
            $appointment->id,
            $random
        );

        return [
            'room_name' => $roomName,
            'room_url'  => $this->roomUrlFor($roomName),
        ];
    }

    /**
     * Build a joinable meet URL for an existing room name.
     *
     * @param  string  $mode  One of config('jitsi.modes'): consult | group |
     *                        broadcast_host | broadcast_view.
     */
    public function roomUrlFor(string $roomName, string $mode = 'consult'): string
    {
        $config = collect(array_merge(
            config('jitsi.iframe_config', []),
            config("jitsi.modes.{$mode}", []),
        ))
            ->map(function ($v, $k) {
                $key = match (true) {
                    str_starts_with($k, 'config.') => $k,
                    str_starts_with($k, 'interfaceConfig.') => $k,
                    default => 'config.'.$k,
                };

                return $key.'='.match (true) {
                    is_bool($v) => $v ? 'true' : 'false',
                    is_array($v) => rawurlencode(json_encode($v)),
                    default => (string) $v,
                };
            })
            ->implode('&');

        $base = rtrim((string) config('jitsi.base_url'), '/').'/'.$roomName;

        return $config === '' ? $base : $base.'#'.$config;
    }

    /**
     * Mint a JWT for a user joining a room. Returns null when JWT auth is
     * disabled (the default against meet.jit.si).
     *
     * @param  bool  $asModerator  Professionial/host gets Jitsi moderator rights.
     */
    public function issueToken(User $user, string $roomName, bool $asModerator = false, string $mode = 'consult'): ?string
    {
        if (! config('jitsi.use_jwt')) {
            return null;
        }

        $now = now()->timestamp;
        // Being platform staff does not make someone a moderator of a
        // private room; only the host of this room is.
        $isModerator = $asModerator;

        $payload = [
            'iss' => config('jitsi.jwt.app_id'),
            'aud' => config('jitsi.jwt.audience'),
            // Prosody accepts * for single-tenant docker deployments.
            'sub' => config('jitsi.jwt.subject', '*'),
            'room' => $roomName,
            'exp' => $now + (int) config('jitsi.jwt.lifetime_seconds'),
            'iat' => $now,
            'nbf' => $now,
            'context' => [
                'user' => [
                    'id' => (string) $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'moderator' => $isModerator ? 'true' : 'false',
                    // Read by the visitors / permissions modules when enabled.
                    'role' => $mode === 'broadcast_view' ? 'visitor' : 'participant',
                ],
                // Nobody but the host records or restreams a room.
                'features' => [
                    'recording'     => 'false',
                    'livestreaming' => 'false',
                    'transcription' => 'false',
                    'outbound-call' => 'false',
                    'screen-sharing' => $mode === 'broadcast_view' ? 'false' : 'true',
                ],
            ],
        ];

        return JWT::encode(
            $payload,
            config('jitsi.jwt.secret'),
            config('jitsi.jwt.algorithm')
        );
    }

    /**
     * Everything a client needs to enter a named room in a given mode.
     *
     * @return array{room_name:string, room_url:string, token:?string, is_host:bool, provider:string, mode:string, can_publish:bool}
     */
    public function sessionFor(User $user, string $roomName, string $mode, bool $isHost): array
    {
        return [
            'room_url'    => $this->roomUrlFor($roomName, $mode),
            'room_name'   => $roomName,
            'token'       => $this->issueToken($user, $roomName, $isHost, $mode),
            'is_host'     => $isHost,
            'provider'    => 'jitsi',
            'mode'        => $mode,
            'can_publish' => $mode !== 'broadcast_view',
        ];
    }

    /** A fresh, unguessable room name: `<prefix><kind>-<id>-<random>`. */
    public function newRoomName(string $kind, int $id): string
    {
        return sprintf('%s%s-%d-%s', config('jitsi.room_prefix'), $kind, $id, Str::lower(Str::random(10)));
    }

    /**
     * Room + token for a participant.
     *
     * @return array{room_name: string, room_url: string, token: ?string, jwt_required: bool, is_host: bool}
     */
    public function authorize(Appointment $appointment, User $user, bool $asModerator = false): array
    {
        $room = $this->generateRoom($appointment);

        return [
            'room_name' => $room['room_name'],
            'room_url' => $room['room_url'],
            'token' => $this->issueToken($user, $room['room_name'], $asModerator),
            'jwt_required' => (bool) config('jitsi.use_jwt'),
            'is_host' => $asModerator,
        ];
    }
}
