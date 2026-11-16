<?php

namespace App\Events;

use App\Models\Appointment;
use App\Models\CallSession;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasts a session state change to the two parties (client + pro).
 * Channel: private-appointments.{userId} — each user subscribes to
 * their own user-id channel.
 */
class SessionStateChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Appointment $appointment,
        public CallSession $session,
        public string $state,    // 'started' | 'ended' | 'recording_ready'
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('appointments.' . $this->appointment->user_id),
            new PrivateChannel('appointments.' . $this->appointment->professional_user_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'session.state';
    }

    public function broadcastWith(): array
    {
        return [
            'appointment_id' => $this->appointment->id,
            'session_id'     => $this->session->id,
            'state'          => $this->state,
            'room_name'      => $this->session->room_name,
            'recording_url'  => $this->session->recording_url,
            'recording_status' => $this->session->recording_status,
            'started_at'     => $this->session->started_at?->toIso8601String(),
            'ended_at'       => $this->session->ended_at?->toIso8601String(),
        ];
    }
}