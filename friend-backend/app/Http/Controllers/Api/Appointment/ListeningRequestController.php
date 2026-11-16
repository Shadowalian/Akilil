<?php

namespace App\Http\Controllers\Api\Appointment;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Client asks a professional for an on-demand listening session.
 * Allowed when the pro offers free listening (or rate is $0).
 * Stays pending until the pro accepts or declines.
 */
class ListeningRequestController extends Controller
{
    /**
     * POST /api/appointments/listening-request
     */
    public function store(Request $request): JsonResponse
    {
        $client = $request->user();
        abort_unless($client->role === 'user', 403, 'Only clients can request listening.');

        $data = $request->validate([
            'professional_user_id' => ['required', 'integer', 'exists:users,id'],
            'message' => ['nullable', 'string', 'max:1000'],
            'session_type' => ['nullable', 'in:video,voice'],
        ]);

        $pro = User::where('id', $data['professional_user_id'])
            ->where('role', 'professional')
            ->firstOrFail();

        $profile = ProfessionalProfile::where('user_id', $pro->id)->first();
        abort_unless($profile, 422, 'Professional has no profile.');
        abort_unless($profile->verification_status === 'approved', 422, 'Professional is not verified.');
        abort_unless($profile->is_accepting_clients, 422, 'Professional is not accepting clients.');

        $offersFree = (bool) ($profile->offers_free_listening ?? false)
            || (int) $profile->hourly_rate_cents === 0;
        abort_unless($offersFree, 422, 'This listener is not offering free listening right now.');

        // One open request per client↔pro pair.
        $existing = Appointment::where('user_id', $client->id)
            ->where('professional_user_id', $pro->id)
            ->where('kind', 'listening_request')
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->exists();
        if ($existing) {
            throw ValidationException::withMessages([
                'professional_user_id' => ['You already have an open listening request with this listener.'],
            ]);
        }

        $duration = (int) ($profile->session_duration_minutes ?: 45);

        $appt = Appointment::create([
            'user_id' => $client->id,
            'professional_user_id' => $pro->id,
            'professional_profile_id' => $profile->id,
            'scheduled_at' => now()->subMinute(),
            'duration_minutes' => $duration,
            'session_type' => $data['session_type'] ?? 'video',
            'kind' => 'listening_request',
            'status' => 'pending',
            'price_cents' => 0,
            'currency' => $profile->currency ?? 'USD',
            'user_timezone' => $client->timezone ?? 'UTC',
            'professional_timezone' => $pro->timezone ?? 'UTC',
            'client_note' => $data['message'] ?? null,
        ]);

        $appt->load(['client', 'professional']);

        return response()->json([
            'message' => 'Listening request sent. Waiting for the listener to accept.',
            'appointment' => (new AppointmentResource($appt))->toArray($request),
        ], 201);
    }

    /**
     * POST /api/appointments/{id}/accept
     */
    public function accept(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $appt = Appointment::with(['client', 'professional'])->findOrFail($id);
        abort_unless((int) $user->id === (int) $appt->professional_user_id, 403, 'Only the listener can accept.');
        abort_unless($appt->status === 'pending', 422, 'Request is not pending.');

        $appt->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
            'scheduled_at' => now()->subMinute(),
        ]);

        return response()->json([
            'message' => 'Listening request accepted. You can start the session now.',
            'appointment' => (new AppointmentResource($appt->fresh()->load(['client', 'professional'])))->toArray($request),
        ]);
    }

    /**
     * POST /api/appointments/{id}/decline
     */
    public function decline(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $appt = Appointment::with(['client', 'professional'])->findOrFail($id);
        abort_unless((int) $user->id === (int) $appt->professional_user_id, 403, 'Only the listener can decline.');
        abort_unless($appt->status === 'pending', 422, 'Request is not pending.');

        $reason = $request->input('reason', 'declined_by_professional');

        DB::transaction(function () use ($appt, $user, $reason) {
            $appt->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
                'cancelled_by' => $user->id,
                'cancellation_reason' => $reason,
            ]);
        });

        return response()->json([
            'message' => 'Listening request declined.',
            'appointment' => (new AppointmentResource($appt->fresh()->load(['client', 'professional'])))->toArray($request),
        ]);
    }
}
