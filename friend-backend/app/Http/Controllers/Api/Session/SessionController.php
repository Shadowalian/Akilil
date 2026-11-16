<?php

namespace App\Http\Controllers\Api\Session;

use App\Events\SessionStateChanged;
use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\CallSession;
use App\Services\JitsiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SessionController extends Controller
{
    public function __construct(private JitsiService $jitsi) {}

    /**
     * POST /api/appointments/{id}/session/start
     * Auth: only the appointment's client or professional.
     */
    public function start(Request $request, int $appointmentId): JsonResponse
    {
        $appt = Appointment::with(['client', 'professional'])->findOrFail($appointmentId);
        $this->authorizeParties($request->user(), $appt);

        if (! in_array($appt->status, ['pending', 'confirmed', 'in_progress'], true)) {
            throw ValidationException::withMessages([
                'status' => ['Session can only be started for pending/confirmed appointments.'],
            ]);
        }

        // Listening requests must be accepted before either side can open video.
        if (($appt->kind ?? 'scheduled') === 'listening_request' && $appt->status === 'pending') {
            throw ValidationException::withMessages([
                'status' => ['Waiting for the listener to accept this request.'],
            ]);
        }

        // Free / $0 sessions and listening skip the join window.
        // Scheduled paid sessions: open 2h early, stay open 2h after end.
        $isFreeTest = (int) ($appt->price_cents ?? 0) === 0
            || ($appt->kind ?? '') === 'listening_request';
        if ($appt->scheduled_at && ! $isFreeTest) {
            $open = $appt->scheduled_at->copy()->subHours(2);
            $close = $appt->scheduled_at->copy()->addMinutes(($appt->duration_minutes ?? 45) + 120);
            if (now()->lt($open) || now()->gt($close)) {
                throw ValidationException::withMessages([
                    'scheduled_at' => ['Session is outside the join window. Come back closer to your appointment time.'],
                ]);
            }
        }

        $user = $request->user();
        $isHost = (int) $user->id === (int) $appt->professional_user_id;

        $jitsi = null;
        $callSession = DB::transaction(function () use ($user, $appt, $isHost, &$jitsi) {
            $existing = CallSession::where('appointment_id', $appt->id)->first();

            if ($existing && $existing->room_name && $existing->room_name !== 'pending') {
                $jitsi = [
                    'room_name' => $existing->room_name,
                    'room_url' => $this->jitsi->roomUrlFor($existing->room_name),
                    'token' => $this->jitsi->issueToken($user, $existing->room_name, $isHost),
                    'is_host' => $isHost,
                ];
                $existing->update([
                    'status' => 'active',
                    'room_token' => $jitsi['token'],
                ]);
                if ($appt->status !== 'in_progress') {
                    $appt->update([
                        'status' => 'in_progress',
                        'started_at' => $appt->started_at ?? now(),
                    ]);
                }

                return $existing;
            }

            $jitsi = $this->jitsi->authorize($appt, $user, $isHost);
            $session = CallSession::updateOrCreate(
                ['appointment_id' => $appt->id],
                [
                    'started_at' => now(),
                    'provider' => 'jitsi',
                    'room_name' => $jitsi['room_name'],
                    'room_token' => $jitsi['token'],
                    'status' => 'active',
                ]
            );
            $appt->update([
                'status' => 'in_progress',
                'started_at' => $session->started_at,
            ]);

            return $session;
        });

        event(new SessionStateChanged($appt->fresh(), $callSession, 'started'));

        return response()->json([
            'session' => [
                'id' => $callSession->id,
                'room_url' => $jitsi['room_url'],
                'room_name' => $jitsi['room_name'],
                'token' => $jitsi['token'],
                'started_at' => $callSession->started_at?->toIso8601String(),
                'provider' => 'jitsi',
                'is_host' => $isHost,
            ],
            'display_name' => $user->name,
            'appointment' => [
                'id' => $appt->id,
                'status' => $appt->fresh()->status,
            ],
        ]);
    }

    /**
     * POST /api/appointments/{id}/session/end
     * Only the professional (host) or admin ends the session for everyone.
     */
    public function end(Request $request, int $appointmentId): JsonResponse
    {
        $appt = Appointment::findOrFail($appointmentId);
        $user = $request->user();
        $this->authorizeParties($user, $appt);

        $isHost = (int) $user->id === (int) $appt->professional_user_id;
        $isAdmin = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support']);
        abort_unless($isHost || $isAdmin, 403, 'Only the host can end the session for everyone.');

        $callSession = $appt->callSession;
        abort_unless($callSession, 404, 'No active session.');

        if ($callSession->status === 'completed') {
            return response()->json([
                'session' => [
                    'id' => $callSession->id,
                    'duration_seconds' => $callSession->duration_seconds,
                    'recording_status' => $callSession->recording_status,
                ],
                'appointment' => ['id' => $appt->id, 'status' => $appt->status],
            ]);
        }

        DB::transaction(function () use ($appt, $callSession) {
            $callSession->update([
                'ended_at' => now(),
                'duration_seconds' => $callSession->started_at
                    ? $callSession->started_at->diffInSeconds(now())
                    : null,
                'status' => 'completed',
            ]);
            $appt->update([
                'status' => 'completed',
                'ended_at' => now(),
            ]);
        });

        event(new SessionStateChanged($appt->fresh(), $callSession->fresh(), 'ended'));

        return response()->json([
            'session' => [
                'id' => $callSession->id,
                'duration_seconds' => $callSession->duration_seconds,
                'recording_status' => $callSession->recording_status,
            ],
            'appointment' => ['id' => $appt->id, 'status' => $appt->status],
        ]);
    }

    private function authorizeParties(\App\Models\User $user, Appointment $appt): void
    {
        $isParty = $user->id === $appt->user_id || $user->id === $appt->professional_user_id;
        $isAdmin = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support']);
        abort_unless($isParty || $isAdmin, 403, 'Not your session.');
    }
}
