<?php

namespace App\Services;

use App\Models\Earning;
use App\Models\Payout;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * The professional-side ledger. Clients pay into the platform through
 * their wallet; this records what each paid thing is worth to the
 * professional after the platform fee, and what they can withdraw.
 */
class EarningsService
{
    /**
     * Record an earning for a paid source. Idempotent per source, so
     * retried requests and repeated "end session" calls never double-pay.
     */
    public function record(User $professional, string $kind, int $grossCents, Model $source, ?string $currency = null): ?Earning
    {
        if ($grossCents <= 0) {
            return null;
        }

        $feePercent = (float) config('akilil.fees.'.match ($kind) {
            'gift'       => 'gift_percent',
            'group_seat' => 'group_percent',
            default      => 'session_percent',
        }, 20);
        $fee = (int) round($grossCents * $feePercent / 100);

        return Earning::firstOrCreate(
            ['source_type' => $source->getMorphClass(), 'source_id' => $source->getKey()],
            [
                'professional_user_id' => $professional->id,
                'kind'        => $kind,
                'gross_cents' => $grossCents,
                'fee_cents'   => $fee,
                'net_cents'   => $grossCents - $fee,
                'currency'    => $currency ?: config('akilil.currency'),
                'status'      => 'available',
            ]
        );
    }

    /** Undo an earning (the client was refunded). */
    public function reverse(Model $source): void
    {
        Earning::where('source_type', $source->getMorphClass())
            ->where('source_id', $source->getKey())
            ->update(['status' => 'reversed']);
    }

    /** Net earned and not reversed, minus everything already requested or paid out. */
    public function availableCents(User $professional): int
    {
        $earned = (int) Earning::where('professional_user_id', $professional->id)
            ->where('status', 'available')
            ->sum('net_cents');

        $withdrawn = (int) Payout::where('professional_user_id', $professional->id)
            ->whereIn('status', ['scheduled', 'processing', 'succeeded'])
            ->sum('amount_cents');

        return max(0, $earned - $withdrawn);
    }
}
