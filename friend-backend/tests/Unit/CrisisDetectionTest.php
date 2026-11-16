<?php

namespace Tests\Unit;

use App\Services\CrisisDetectionService;
use Tests\TestCase;

/**
 * Unit tests for the v1 crisis-detection heuristic.
 *
 * These tests are intentionally narrow — they assert behavior of the
 * current keyword list, NOT that this is a "good" detector. Real production
 * (Task 5's explicit caveats) needs clinical review + labeled data.
 */
class CrisisDetectionTest extends TestCase
{
    private CrisisDetectionService $svc;

    protected function setUp(): void
    {
        parent::setUp();
        $this->svc = new CrisisDetectionService();
    }

    public function test_empty_text_does_not_flag(): void
    {
        $r = $this->svc->analyze('');
        $this->assertFalse($r['flag']);
        $this->assertEquals(0.0, $r['severity']);
    }

    public function test_neutral_text_does_not_flag(): void
    {
        $r = $this->svc->analyze('I had a great walk today and felt grateful for the sunshine.');
        $this->assertFalse($r['flag']);
    }

    public function test_explicit_self_harm_phrase_flags(): void
    {
        $r = $this->svc->analyze('I want to die tonight.');
        $this->assertTrue($r['flag']);
        $this->assertGreaterThanOrEqual(0.5, $r['severity']);
        $this->assertNotEmpty($r['signals']);
    }

    public function test_suicidal_phrase_alone_does_not_flag_at_v1(): void
    {
        // v1 heuristic: "suicidal" alone is below the FLAG_THRESHOLD
        // (0.65 < 0.7). The intent is to require a second signal before
        // an admin alert. This avoids alerting on common discourse
        // like "I felt suicidal but it's getting better".
        $r = $this->svc->analyze("I've been thinking about suicide for weeks.");
        $this->assertFalse($r['flag']);
        $this->assertGreaterThan(0.5, $r['severity']);
    }

    public function test_self_harm_direct_phrase_flags_highest(): void
    {
        $r = $this->svc->analyze('I want to end my life.');
        $this->assertTrue($r['flag']);
        $this->assertGreaterThan(0.6, $r['severity']);
    }

    public function test_soft_signals_alone_below_threshold(): void
    {
        $r = $this->svc->analyze('I feel hopeless and empty today.');
        $this->assertFalse($r['flag'], 'Soft signals alone should not flag at v1 threshold.');
    }

    public function test_combined_signals_can_flag(): void
    {
        $r = $this->svc->analyze("I'm worthless, there's no point, and nobody would miss me.");
        $this->assertTrue($r['flag']);
    }

    public function test_severity_is_capped_at_one(): void
    {
        $r = $this->svc->analyze('I want to die, I want to kill myself, I want to end my life, suicide suicide suicide.');
        $this->assertLessThanOrEqual(1.0, $r['severity']);
    }

    public function test_recorded_signals_include_match_metadata(): void
    {
        $r = $this->svc->analyze('I want to kill myself.');
        $hasPhrase = collect($r['signals'])->contains(fn ($s) => $s['signal'] === 'phrase');
        $this->assertTrue($hasPhrase, 'Crisis signals should record the matched phrase for reviewer audit.');
    }
}