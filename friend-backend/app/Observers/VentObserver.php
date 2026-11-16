<?php

namespace App\Observers;

use App\Jobs\ProcessContentForCrisisFlagsJob;
use App\Models\Vent;

class VentObserver
{
    public function created(Vent $vent): void
    {
        // Skip anonymous vents with no author; the job handler will also
        // bail on null author_id, but skipping dispatch is cheaper.
        if (! $vent->author_user_id) {
            return;
        }
        ProcessContentForCrisisFlagsJob::dispatch(
            'vent',
            $vent->id,
            (string) ($vent->content ?? ''),
            $vent->author_user_id,
        );
    }
}