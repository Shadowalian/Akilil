<?php

namespace App\Jobs;

use App\Models\CrisisFlag;
use App\Models\JournalEntry;
use App\Models\Message;
use App\Models\User;
use App\Models\Vent;
use App\Notifications\CrisisEscalationNotification;
use App\Services\CrisisDetectionService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Listens for new journal entries, vents, and messages; runs them through
 * the CrisisDetectionService; if severity crosses the threshold, creates
 * a CrisisFlag row + dispatches a notification to every admin/support user.
 *
 * Admins are the deciding step. This job NEVER auto-takes irreversible
 * action — that is the explicit design constraint from Task 5.
 *
 * The job is queued so a slow API service or NLU provider (Task 5 upgrade
 * path) doesn't block the user's POST.
 */
class ProcessContentForCrisisFlagsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        public string $sourceType,        // 'journal' | 'vent' | 'message'
        public int    $sourceId,
        public string $text,
        public ?int   $authorUserId = null,
    ) {}

    public function handle(CrisisDetectionService $detector): void
    {
        try {
            $result = $detector->analyze($this->text);
        } catch (\Throwable $e) {
            Log::error('Crisis detection analyzer failed', [
                'source' => $this->sourceType,
                'source_id' => $this->sourceId,
                'error' => $e->getMessage(),
            ]);
            return;
        }

        if (! $result['flag']) {
            return;
        }

        $authorId = $this->authorUserId ?? $this->resolveAuthorId();
        if (! $authorId) {
            // Anonymous vent with no author → skip flag (no one to follow up with).
            return;
        }

        $flag = CrisisFlag::create([
            'user_id'         => $authorId,
            'source_type'     => $this->sourceType,
            'source_id'       => $this->sourceId,
            'severity'        => $result['severity'],
            'matched_signals' => $result['signals'],
            'status'          => 'open',
        ]);

        $this->notifyAdmins($flag);
    }

    private function resolveAuthorId(): ?int
    {
        return match ($this->sourceType) {
            'journal' => JournalEntry::find($this->sourceId)?->user_id,
            'vent'    => Vent::find($this->sourceId)?->author_user_id,
            'message' => Message::find($this->sourceId)?->sender_id,
            default   => null,
        };
    }

    private function notifyAdmins(CrisisFlag $flag): void
    {
        $recipients = User::query()
            ->whereHas('roles', fn ($q) => $q->whereIn('name', ['admin', 'support']))
            ->get();
        foreach ($recipients as $admin) {
            $admin->notify(new CrisisEscalationNotification($flag));
        }
    }
}