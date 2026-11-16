<?php

namespace Database\Factories;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Message>
 */
class MessageFactory extends Factory
{
    protected $model = Message::class;

    public function definition(): array
    {
        return [
            'client_uuid'     => null,
            'conversation_id' => Conversation::factory(),
            'sender_id'       => User::factory(),
            'parent_message_id' => null,
            'message_type'    => 'text',
            'content_encrypted' => fake()->sentence(),
            'is_edited'       => false,
            'is_deleted'      => false,
            'flagged_status'  => 'none',
        ];
    }
}