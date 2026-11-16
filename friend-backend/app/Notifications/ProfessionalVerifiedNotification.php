<?php

namespace App\Notifications;

use App\Models\ProfessionalProfile;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ProfessionalVerifiedNotification extends Notification
{
    use Queueable;

    public function __construct(public ProfessionalProfile $profile) {}

    public function via($notifiable): array
    {
        return ['database', 'mail'];
    }

    public function toArray($notifiable): array
    {
        return [
            'type'         => 'professional_verified',
            'profile_id'   => $this->profile->id,
            'category_id'  => $this->profile->category_id,
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("You're verified on Akilil!")
            ->line('Your account has been approved and your verified badge is now active.');
    }
}