<?php

namespace App\Support;

/**
 * Base32 (RFC 4648) encoder/decoder — used for TOTP secrets (Google
 * Authenticator format) and recovery codes. Pure PHP, no dependency.
 *
 *   Base32::encode($bytes)   → "JBSWY3DPEHPK3PXP"
 *   Base32::decode("JBSW...") → bytes
 *
 * Standard alphabet: A-Z 2-7. Output is uppercased, no padding by default
 * (Google Authenticator accepts both, but padding-free is cleaner).
 */
final class Base32
{
    private const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    private const PAD = '=';

    public static function encode(string $bytes, bool $pad = false): string
    {
        $output = '';
        $buffer = 0;
        $bitsLeft = 0;
        $len = strlen($bytes);

        for ($i = 0; $i < $len; $i++) {
            $buffer = ($buffer << 8) | ord($bytes[$i]);
            $bitsLeft += 8;
            while ($bitsLeft >= 5) {
                $bitsLeft -= 5;
                $idx = ($buffer >> $bitsLeft) & 0x1F;
                $output .= self::ALPHABET[$idx];
            }
        }

        if ($bitsLeft > 0) {
            $idx = ($buffer << (5 - $bitsLeft)) & 0x1F;
            $output .= self::ALPHABET[$idx];
        }

        if ($pad) {
            $remainder = strlen($output) % 8;
            if ($remainder !== 0) {
                $output .= str_repeat(self::PAD, 8 - $remainder);
            }
        }
        return $output;
    }

    /**
     * Decode a base32 string back to bytes. Returns false on invalid input.
     */
    public static function decode(string $input): string|false
    {
        $input = strtoupper(rtrim($input, self::PAD));
        $len = strlen($input);
        if ($len === 0) {
            return '';
        }

        // Reject any char not in the alphabet
        if (! preg_match('/^[A-Z2-7]+$/', $input)) {
            return false;
        }

        $output = '';
        $buffer = 0;
        $bitsLeft = 0;

        for ($i = 0; $i < $len; $i++) {
            $idx = strpos(self::ALPHABET, $input[$i]);
            if ($idx === false) {
                return false;
            }
            $buffer = ($buffer << 5) | $idx;
            $bitsLeft += 5;
            if ($bitsLeft >= 8) {
                $bitsLeft -= 8;
                $output .= chr(($buffer >> $bitsLeft) & 0xFF);
            }
        }
        return $output;
    }
}