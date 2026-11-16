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

    /** Build a joinable meet URL for an existing room name. */
    public function roomUrlFor(string $roomName): string
    {
        $config = collect(config('jitsi.iframe_config', []))
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
    public function issueToken(User $user, string $roomName, bool $asModerator = false): ?string
    {
        if (! config('jitsi.use_jwt')) {
            return null;
        }

        $now = now()->timestamp;
        $isModerator = $asModerator
            || $user->hasAnyRole(['admin', 'support', 'moderator']);

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
