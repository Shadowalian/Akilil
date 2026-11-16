<?php

namespace App\Observers;

use App\Jobs\ProcessContentForCrisisFlagsJob;
use App\Models\JournalEntry;

/**
 * Dispatches a ProcessContentForCrisisFlagsJob when a journal entry is
 * created. The job is queued so the user's POST doesn't block on
 * detection. Failures are logged inside the job — observers stay fast.
 */
class JournalEntryObserver
{
    public function created(JournalEntry $entry): void
    {
        ProcessContentForCrisisFlagsJob::dispatch(
            'journal',
            $entry->id,
            (string) $entry->content,
            $entry->user_id,
        );
    }
}