<?php

namespace App\Services;

use App\Support\Base32;
use Illuminate\Support\Str;

/**
 * TwoFactorService — TOTP (RFC 6238) and recovery-code management.
 *
 * No third-party TOTP library; the algorithm is small and well-defined:
 *   1. secret = random 20-byte value, base32-encoded (Google Authenticator format)
 *   2. counter = floor(now / 30)               // 30-second window
 *   3. hmac    = HMAC-SHA1(secret_bytes, pack('N*', counter))   // 8-byte big-endian counter
 *   4. offset  = hmac[19] & 0x0F
 *   5. code    = (last 4 bytes of hmac at offset, mask top bit) % 1_000_000
 *
 * We use the `step 30s` and `digits 6` defaults Google Authenticator expects.
 * Recovery codes are 10 single-use random strings, hashed at rest in the
 * totp_recovery_codes JSON column (Laravel's `encrypted:array` cast).
 *
 * Built in Task 2 so the User model + auth flow can wire it from day one.
 * The admin panel middleware (Task 6) reads `totp_enabled` to enforce.
 */
class TwoFactorService
{
    public const PERIOD = 30;
    public const DIGITS = 6;
    public const RECOVERY_CODE_COUNT = 10;
    public const RECOVERY_CODE_BYTES = 10;       // 20-char base32 → ~10 bytes of entropy

    /**
     * Generate a fresh secret. Returns a base32-encoded string
     * (compatible with Google Authenticator, Authy, 1Password, etc).
     */
    public function generateSecret(): string
    {
        return Base32::encode(random_bytes(20));
    }

    /**
     * Current TOTP code for the given secret. Used internally for tests;
     * clients never see this directly.
     */
    public function currentCode(string $secret, ?int $timestamp = null): string
    {
        $timestamp ??= time();
        $counter = intdiv($timestamp, self::PERIOD);
        return $this->codeAtCounter($secret, $counter);
    }

    /**
     * Verify a user-supplied code. Returns true if the code matches
     * the current window or the ±1 window (handles slight clock drift
     * between server and authenticator app).
     */
    public function verifyCode(string $secret, string $code, ?int $timestamp = null): bool
    {
        $code = preg_replace('/\s+/', '', $code);   // strip spaces
        if (! ctype_digit($code) || strlen($code) !== self::DIGITS) {
            return false;
        }
        $timestamp ??= time();
        $counter = intdiv($timestamp, self::PERIOD);
        // ±1 window tolerance.
        foreach ([-1, 0, 1] as $offset) {
            if (hash_equals($this->codeAtCounter($secret, $counter + $offset), $code)) {
                return true;
            }
        }
        return false;
    }

    /**
     * otpauth:// URL — encoded into the QR code for Google Authenticator.
     * Format: otpauth://totp/{label}?secret={secret}&issuer={issuer}&period=30&digits=6
     */
    public function otpAuthUrl(string $email, string $secret, string $issuer = 'Akilil'): string
    {
        $label = rawurlencode($issuer . ':' . $email);
        $params = http_build_query([
            'secret'    => $secret,
            'issuer'    => $issuer,
            'period'    => self::PERIOD,
            'digits'    => self::DIGITS,
            'algorithm' => 'SHA1',
        ]);
        return "otpauth://totp/{$label}?{$params}";
    }

    /**
     * Generate a fresh set of one-time recovery codes.
     * Returned as plain text — caller MUST hash them before storage.
     * (We store the plaintext only briefly in the API response so the
     * user can save them; subsequent reads return the hashed versions.)
     *
     * @return string[]
     */
    public function generateRecoveryCodes(): array
    {
        $codes = [];
        for ($i = 0; $i < self::RECOVERY_CODE_COUNT; $i++) {
            // 10 random bytes → base32 → strip padding → uppercase.
            // ~16 chars of human-readable entropy per code.
            $codes[] = strtoupper(rtrim(Base32::encode(random_bytes(self::RECOVERY_CODE_BYTES)), '='));
        }
        return $codes;
    }

    /* ---- internals ---- */

    private function codeAtCounter(string $secret, int $counter): string
    {
        $secretBytes = Base32::decode($secret);
        if ($secretBytes === false || strlen($secretBytes) < 16) {
            throw new \InvalidArgumentException('Invalid TOTP secret.');
        }
        // 8-byte big-endian counter (N* unpacks as 4-byte unsigned ints × N)
        $binCounter = pack('N*', 0, $counter);
        $hash = hash_hmac('sha1', $binCounter, $secretBytes, true);

        $offset = ord($hash[19]) & 0x0F;
        $truncated = (
            ((ord($hash[$offset])     & 0x7F) << 24) |
            ((ord($hash[$offset + 1]) & 0xFF) << 16) |
            ((ord($hash[$offset + 2]) & 0xFF) <<  8) |
            ((ord($hash[$offset + 3]) & 0xFF)      )
        );
        return str_pad((string) ($truncated % 10 ** self::DIGITS), self::DIGITS, '0', STR_PAD_LEFT);
    }
}