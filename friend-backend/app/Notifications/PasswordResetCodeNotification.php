<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** A short code the person types into the app to choose a new password. */
class PasswordResetCodeNotification extends Notification
{
    use Queueable;

    public function __construct(public string $code) {}

    public function via($notifiable): array
    {
        return ['mail'];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your Akilil password reset code')
            ->line('Enter this code in the Akilil app to choose a new password:')
            ->line($this->code)
            ->line('It expires in 15 minutes. If you did not ask for this, you can ignore this email — your password has not changed.');
    }
}
