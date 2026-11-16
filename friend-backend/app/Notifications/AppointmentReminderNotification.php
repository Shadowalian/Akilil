<?php

namespace App\Notifications;

use App\Models\Appointment;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class AppointmentReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Appointment $appointment, public string $kind) {}

    /**
     * Channels wired in Task 4. For Task 3 we ship a stub mail channel
     * so the queued job has somewhere to send. The broadcast + push
     * channels are added in Task 4.
     */
    public function via($notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable): MailMessage
    {
        $when = $this->appointment->scheduled_at?->toDayDateTimeString() ?? 'soon';
        $verb = $this->kind === 'reminder_1h' ? 'in 1 hour' : 'in 24 hours';
        return (new MailMessage)
            ->subject("Session {$verb} — Akilil")
            ->line("Your session with {$this->appointment->professional->name} is scheduled for {$when}.")
            ->line("Join the call from the app 5 minutes before the start time.");
    }

    public function toArray($notifiable): array
    {
        return [
            'type'           => $this->kind,
            'appointment_id' => $this->appointment->id,
            'scheduled_at'   => $this->appointment->scheduled_at?->toIso8601String(),
        ];
    }
}