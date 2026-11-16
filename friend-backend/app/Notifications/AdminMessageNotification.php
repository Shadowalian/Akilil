<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Generic admin message notification — used for ad-hoc admin→user
 * comms (verification rejection, suspension notice, etc.) until we
 * build a proper messaging thread between admin and user in a future task.
 */
class AdminMessageNotification extends Notification
{
    use Queueable;

    public function __construct(public string $subject, public string $body) {}

    public function via($notifiable): array { return ['mail', 'database']; }

    public function toArray($notifiable): array
    {
        return ['subject' => $this->subject, 'body' => $this->body];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)->subject($this->subject)->line($this->body);
    }
}