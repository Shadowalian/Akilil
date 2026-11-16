<?php

namespace App\Notifications;

use App\Models\Appointment;
use App\Models\AppointmentParticipant;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Emailed to the partner / family member named on a couples or family
 * booking. They accept with the code from inside the Akilil app.
 */
class SessionInviteNotification extends Notification
{
    use Queueable;

    public function __construct(
        public Appointment $appointment,
        public AppointmentParticipant $participant,
        public string $invitedBy,
    ) {}

    public function via($notifiable): array
    {
        return ['mail'];
    }

    public function toMail($notifiable): MailMessage
    {
        $when = $this->appointment->scheduled_at?->toDayDateTimeString();
        $kind = $this->appointment->care_format === 'couples' ? 'couples session' : 'family session';

        return (new MailMessage)
            ->subject("{$this->invitedBy} invited you to an Akilil {$kind}")
            ->greeting("Hello {$this->participant->name},")
            ->line("{$this->invitedBy} booked a {$kind} on Akilil for {$when} (UTC) and would like you to join.")
            ->line('Open the Akilil app, sign in or create an account with this email address, and the invitation will be waiting under Sessions.')
            ->line('If you are asked for an invitation code, use:')
            ->line($this->participant->invite_token)
            ->line('You will join from your own device. There is nothing for you to pay.');
    }
}
