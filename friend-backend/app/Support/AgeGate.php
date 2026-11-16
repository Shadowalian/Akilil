<?php

namespace App\Support;

use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * One place for "is this person old enough / allowed to pay" checks, so
 * every money-moving endpoint answers the same way.
 */
class AgeGate
{
    /**
     * Booking, topping up, reserving and gifting all spend money and form
     * an agreement with a professional: adults with a known age only.
     */
    public static function requireAdultPayer(User $user): void
    {
        if ($user->guardian_user_id) {
            self::deny('guardian_required', 'Your parent or guardian manages bookings and payments for this account.', 403);
        }
        self::requireKnownAge($user);
        if ($user->age() < (int) config('akilil.adult_age')) {
            self::deny('guardian_required', 'You must be 18 or older. A parent or guardian can book for you from their account.', 403);
        }
    }

    public static function requireKnownAge(User $user): void
    {
        if ($user->age() === null) {
            self::deny('date_of_birth_required', 'Please add your date of birth to continue.', 422);
        }
    }

    public static function requireMinAge(User $user, int $minAge, string $what): void
    {
        self::requireKnownAge($user);
        if ($user->age() < $minAge) {
            self::deny('age_restricted', "You must be at least {$minAge} to {$what}.", 403);
        }
    }

    private static function deny(string $code, string $message, int $status): never
    {
        throw new HttpResponseException(response()->json(['message' => $message, 'code' => $code], $status));
    }
}
