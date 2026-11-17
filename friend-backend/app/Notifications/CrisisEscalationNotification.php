<?php

namespace App\Notifications;

use App\Models\CrisisFlag;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Admin-only crisis-escalation alert. Wired into the Task 5 pipeline:
 * when a journal/vent/message matches the heuristic, CrisisFlag row is
 * created and this notification is dispatched to every admin/support user.
 *
 * CRITICAL: This is a HARM-REDUCTION signal, NOT a diagnostic.
 * Admin review is always the deciding step (see CrisisFlag docblock).
 */
class CrisisEscalationNotification extends Notification
{
    use Queueable;

    public function __construct(public CrisisFlag $flag) {}

    public function via($notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toArray($notifiable): array
    {
        return [
            'type'      => 'crisis_flag',
            'flag_id'   => $this->flag->id,
            'user_id'   => $this->flag->user_id,
            'severity'  => (float) $this->flag->severity,
            'source'    => $this->flag->source_type,
            'kind'      => $this->flag->kind ?? 'content',
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        $flag = $this->flag;
        $user = $flag->user;

        // Someone asked for help: everything staff need to reach them, now.
        if (in_array($flag->kind, ['help_request', 'screener'], true)) {
            $why = $flag->kind === 'screener'
                ? 'answered the PHQ-9 self-harm question with something other than "not at all"'
                : 'asked the Akilil safety team to contact them';

            return (new MailMessage)
                ->error()
                ->subject('URGENT — '.$user?->name.' needs to be contacted')
                ->line("{$user?->name} {$why}.")
                ->line('Phone: '.($flag->contact_phone ?: $user?->phone ?: 'not given'))
                ->line('Email: '.$user?->email)
                ->line('Prefers: '.($flag->contact_method === 'message' ? 'a message' : 'a phone call'))
                ->line('Open the flag, press "I am contacting them", and record what happened: '.url('/admin/crisis-flags'));
        }

        return (new MailMessage)
            ->error()
            ->subject('Akilil — content flagged for review')
            ->line("A user (ID {$flag->user_id}) has content flagged with severity {$flag->severity}.")
            ->line('Review in the admin dashboard: '.url('/admin/crisis-flags'));
    }
}