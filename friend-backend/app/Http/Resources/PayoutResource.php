<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PayoutResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                   => $this->id,
            'professional_user_id' => $this->professional_user_id,
            'amount_cents'         => $this->amount_cents,
            'currency'             => $this->currency,
            'platform_fee_cents'   => $this->platform_fee_cents,
            'status'               => $this->status,
            // The Pro app speaks requested/approved/sent; the DB speaks the
            // gateway lifecycle. Map here so both stay honest.
            'display_status'       => match ($this->status) {
                'scheduled'  => 'requested',
                'processing' => 'approved',
                'succeeded'  => 'sent',
                default      => $this->status,
            },
            'gateway'       => $this->gateway,
            'scheduled_for' => optional($this->scheduled_for)?->toDateString(),
            'processed_at'  => optional($this->processed_at)?->toIso8601String(),
            'created_at'    => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
