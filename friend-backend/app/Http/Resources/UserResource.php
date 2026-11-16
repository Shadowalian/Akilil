<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'email'           => $this->email,
            'role'            => $this->role,
            'locale'          => $this->locale,
            'timezone'        => $this->timezone,
            'avatar_url'      => $this->avatar_path,
            'gender'          => $this->gender,
            'date_of_birth'   => optional($this->date_of_birth)?->toDateString(),
            'email_verified_at' => optional($this->email_verified_at)?->toIso8601String(),
            'two_factor_enabled' => (bool) $this->totp_enabled,
            'has_recovery_codes' => ! empty($this->totp_recovery_codes),
            'is_professional'    => $this->role === 'professional',
            'is_admin'           => method_exists($this->resource, 'hasAnyRole') && $this->hasAnyRole(['admin', 'support', 'moderator']),
            'created_at'         => optional($this->created_at)?->toIso8601String(),
        ];
    }
}