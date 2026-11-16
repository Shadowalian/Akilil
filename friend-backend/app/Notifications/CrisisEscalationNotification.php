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
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->error()
            ->subject('Akilil — content flagged for review')
            ->line("A user (ID {$this->flag->user_id}) has content flagged with severity {$this->flag->severity}.")
            ->line('Review in the admin dashboard: /admin/crisis-flags');
    }
}