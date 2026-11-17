<?php

namespace App\Notifications;

use App\Models\Appointment;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BookingConfirmedNotification extends Notification
{
    use Queueable;

    public function __construct(public Appointment $appointment) {}

    public function via($notifiable): array
    {
        return ['database', 'mail'];
    }

    public function toArray($notifiable): array
    {
        return [
            'type'            => 'booking_confirmed',
            'appointment_id'  => $this->appointment->id,
            'scheduled_at'    => $this->appointment->scheduled_at?->toIso8601String(),
            'professional'    => $this->appointment->professional?->name,
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        $when = $this->appointment->scheduled_at?->toDayDateTimeString();
        return (new MailMessage)
            ->subject('Your Akilil session is confirmed')
            ->line("Your session with {$this->appointment->professional?->name} is confirmed for {$when}.");
    }
}