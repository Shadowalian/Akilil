<?php

namespace App\Services;

use App\Models\JournalEntry;
use App\Models\Message;
use App\Models\Vent;

/**
 * CrisisDetectionService — v1 heuristic content-analysis pipeline.
 *
 * ##########################################################################
 *  ##  IMPORTANT — read before tuning or replacing this code               ##
 * ##########################################################################
 *
 *  This is a v1 KEYWORD + DENSITY heuristic. It is NOT a clinically validated
 *  safety system. It is a HARM-REDUCTION signal — admins are always the
 *  deciding step, never the algorithm.
 *
 *  What this code does today:
 *    - Counts matches against a curated English keyword/regex list
 *      (people who said these things out loud in real crisis-flagged data).
 *    - Counts negative-tone words as a soft signal.
 *    - Returns a severity 0..1 with the matched signals recorded for review.
 *
 *  What this code does NOT do:
 *    - It is not trained on real Akilil data (we have none yet).
 *    - It is not validated for false-negative / false-positive rates.
 *    - It does not detect non-English content (Amharic / Oromo / Tigrinya /
 *      Swahili etc. — see Task 1 localization plan).
 *    - It is not appropriate for irreversible action. Admin review is
 *      always required before any contact.
 *
 *  Before relying on this for live crisis handling:
 *    1. Have someone with clinical / safety expertise review the keyword list.
 *    2. Audit against 200+ real flagged examples (false-pos / false-negs).
 *    3. Replace with a proper ML model — recommended paths:
 *         - Google Perspective API (free tier, English-only)
 *         - OpenAI Moderation API (multilingual, paid)
 *         - Self-hosted classifier on labeled Akilil data
 *    4. Add a confidence-tier display (low / med / high) so reviewers know
 *       when to escalate to phone-call outreach vs routine review.
 *
 *  See ARCHITECTURE.md §8 and the CrisisFlag model docblock.
 */
class CrisisDetectionService
{
    /** Threshold above which a CrisisFlag row is created. */
    public const FLAG_THRESHOLD = 0.7;

    /**
     * High-signal phrases. Each match contributes weight; the score is
     * capped at 1.0. Threshold for flagging is FLAG_THRESHOLD (0.7).
     *
     * v1 weight policy:
     *   - "kill myself" / "end my life"     → 0.85  (clear, alone flags)
     *   - "want to die" / "want to end it"  → 0.75  (clear, alone flags)
     *   - "suicidal"                        → 0.65  (needs a soft signal too)
     *   - Self-harm / no-reason-to-live     → 0.55  (needs another signal)
     */
    private const PHRASES = [
        '/\b(want|wanted|wants|wanting)\s+to\s+(die|end\s+it|disappear|not\s+exist)\b/i'    => 0.75,
        '/\b(kill|end)\s+my\s*self\b/i'                                                   => 0.85,
        '/\b(suicide|suicidal)\b/i'                                                       => 0.65,
        '/\bno\s+reason\s+to\s+(live|go\s+on|continue)\b/i'                                => 0.55,
        '/\bi\s+(shouldn\'?t|don\'?t|won\'?t|can\'?t)\s+(be\s+alive|live|exist|be\s+here)\b/i' => 0.7,
        '/\b(end\s+my\s+life|take\s+my\s+own\s+life|end\s+it\s+all)\b/i'                    => 0.85,
        '/\b(hurt|harm|cut|burn)\s+my\s*self\b/i'                                          => 0.55,
        '/\b(better\s+off\s+without\s+me|nobody\s+would\s+(miss|care))\b/i'                  => 0.5,
    ];

    /** Soft signals — fewer points each, but accumulate. */
    private const SOFT_SIGNALS = [
        'hopeless', 'worthless', 'empty', 'numb', 'alone', 'tired of living',
        'no way out', 'no point', 'give up', 'can\'t go on', 'better off dead',
        'broken', 'trapped', 'suffocating', 'unbearable',
    ];

    /**
     * @return array{flag:bool, severity:float, signals:array<int,array{signal:string,value:string}>}
     */
    public function analyze(string $text): array
    {
        $text = mb_strtolower(trim($text));
        if ($text === '') {
            return ['flag' => false, 'severity' => 0.0, 'signals' => []];
        }

        $severity = 0.0;
        $signals = [];

        foreach (self::PHRASES as $pattern => $weight) {
            if (preg_match($pattern, $text, $m)) {
                $severity += $weight;
                $signals[] = ['signal' => 'phrase', 'value' => $m[0]];
            }
        }

        // Soft signals: count distinct matches, scaled.
        $softHits = 0;
        foreach (self::SOFT_SIGNALS as $word) {
            if (str_contains($text, $word)) {
                $softHits++;
                $signals[] = ['signal' => 'soft_word', 'value' => $word];
            }
        }
        if ($softHits > 0) {
            $severity += min(0.4, $softHits * 0.1);
        }

        $severity = min(1.0, round($severity, 3));

        return [
            'flag'     => $severity >= self::FLAG_THRESHOLD,
            'severity' => $severity,
            'signals'  => $signals,
        ];
    }

    /**
     * Convenience helpers for the observer pipeline — return the source
     * model and the text to analyze.
     */
    public function textFromJournal(JournalEntry $entry): string
    {
        return (string) $entry->content;
    }

    public function textFromVent(Vent $vent): string
    {
        return (string) ($vent->content ?? '');
    }

    public function textFromMessage(Message $message): string
    {
        // content_encrypted is the stored cipher; in v1 the pipeline
        // receives plain text from the request before encryption, so the
        // observer pipeline must capture pre-encryption text. The
        // observer passes the model itself; consumers should use the
        // stored ciphertext as a fallback. (For prod, store a
        // parallel unencrypted hash+headline for the pipeline only.)
        return (string) ($message->content_encrypted ?? '');
    }
}