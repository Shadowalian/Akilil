<?php

namespace App\Notifications;

use App\Models\Payout;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PayoutProcessedNotification extends Notification
{
    use Queueable;

    public function __construct(public Payout $payout) {}

    public function via($notifiable): array
    {
        return ['database', 'mail'];
    }

    public function toArray($notifiable): array
    {
        return [
            'type'         => 'payout_processed',
            'payout_id'    => $this->payout->id,
            'amount_cents' => $this->payout->amount_cents,
            'currency'     => $this->payout->currency,
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        $amount = number_format($this->payout->amount_cents / 100, 2);
        return (new MailMessage)
            ->subject('Your Akilil payout was sent')
            ->line("Your payout of {$amount} {$this->payout->currency} has been processed.");
    }
}