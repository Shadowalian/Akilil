<?php

namespace App\Observers;

use App\Jobs\ProcessContentForCrisisFlagsJob;
use App\Models\Message;

/**
 * For chat messages, the observer sees the stored model AFTER encryption
 * (the controller writes via Message::create which runs the encrypted cast).
 * In v1 this is a known limitation — keyword scan against the ciphertext
 * won't match obvious phrases. The production fix is in Task 10: store a
 * parallel unencrypted-headline column for the pipeline only, then update
 * this observer to dispatch ProcessContentForCrisisFlagsJob with that
 * headline. For now we still dispatch — admins get a "low confidence" alert
 * with the ciphertext hash so they can pivot to the dashboard for review.
 */
class MessageObserver
{
    public function created(Message $message): void
    {
        if ($message->message_type !== 'text') {
            return;     // voice/image not analyzed by v1
        }
        if (! $message->sender_id) {
            return;
        }
        ProcessContentForCrisisFlagsJob::dispatch(
            'message',
            $message->id,
            (string) ($message->content_encrypted ?? ''),
            $message->sender_id,
        );
    }
}