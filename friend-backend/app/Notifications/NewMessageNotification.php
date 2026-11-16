<?php

namespace App\Notifications;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewMessageNotification extends Notification
{
    use Queueable;

    public function __construct(public Message $message, public Conversation $conversation) {}

    public function via($notifiable): array
    {
        // FCM/APNs are wired in Task 10 once device tokens are registered.
        return ['database'];
    }

    public function toArray($notifiable): array
    {
        return [
            'type'             => 'new_message',
            'conversation_id'  => $this->conversation->id,
            'message_id'       => $this->message->id,
            'sender_id'        => $this->message->sender_id,
            'message_type'     => $this->message->message_type,
            'preview'          => $this->message->message_type === 'text'
                ? mb_substr((string) $this->message->content_encrypted, 0, 80)
                : '[' . $this->message->message_type . ']',
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('New message on Akilil')
            ->line('You have a new message from ' . ($this->message->sender?->name ?? 'a friend') . '.');
    }
}