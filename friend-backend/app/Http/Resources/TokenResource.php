<?php

namespace App\Http\Resources;

/**
 * Token envelope used by /api/auth/register* and /api/auth/2fa/challenge.
 *
 * Plain class (not JsonResource) so we can return from a controller via
 * `response()->json($this->toArray($request), 201)` without the
 * JsonResource magic interfering with the payload shape.
 */
class TokenResource
{
    public function __construct(
        public string $token,
        public mixed $user = null,
        public bool $requires2fa = false,
        public ?string $challengeToken = null,
        public ?\Carbon\Carbon $expiresAt = null,
    ) {}

    public function toArray($request): array
    {
        return [
            'token'           => $this->token ?: null,
            'user'            => $this->user ? (new UserResource($this->user))->toArray($request) : null,
            'requires_2fa'    => $this->requires2fa,
            'challenge_token' => $this->challengeToken,
            'expires_at'      => optional($this->expiresAt)?->toIso8601String(),
        ];
    }
}