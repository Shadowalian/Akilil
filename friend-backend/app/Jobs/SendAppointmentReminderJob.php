<?php

namespace App\Jobs;

use App\Models\Appointment;
use App\Notifications\AppointmentReminderNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendAppointmentReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(public int $appointmentId, public string $kind) {}

    public function handle(): void
    {
        $appt = Appointment::find($this->appointmentId);
        if (! $appt || ! in_array($appt->status, ['pending','confirmed'])) {
            return;     // appointment cancelled or completed; drop the reminder
        }
        $appt->client?->notify(new AppointmentReminderNotification($appt, $this->kind));
        $appt->professional?->notify(new AppointmentReminderNotification($appt, $this->kind));
    }
}