<?php

namespace App\Http\Controllers\Api\Appointment;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Free same-room video test call — no wallet debit, joinable immediately.
 * For QA: client ↔ professional can both join without booking/payment.
 */
class TestCallController extends Controller
{
    /**
     * POST /api/appointments/test-call
     *
     * Body (client):  { "professional_user_id": 12 }
     * Body (pro):     { "client_user_id": 5 }  — optional; defaults to a demo client
     */
    public function __invoke(Request $request): JsonResponse
    {
        // Creates a free session with an arbitrary account: demo builds only.
        abort_unless(config('akilil.demo_mode'), 404);

        $user = $request->user();
        $data = $request->validate([
            'professional_user_id' => ['nullable', 'integer', 'exists:users,id'],
            'client_user_id' => ['nullable', 'integer', 'exists:users,id'],
        ]);

        if ($user->role === 'professional') {
            $pro = $user;
            $clientId = $data['client_user_id'] ?? null;
            $client = $clientId
                ? User::where('id', $clientId)->where('role', 'user')->first()
                : User::where('email', 'support@akilil.app')->first()
                    ?? User::where('email', 'demo@akilil.app')->first()
                    ?? User::where('role', 'user')->where('id', '!=', $pro->id)->first();

            if (! $client) {
                throw ValidationException::withMessages([
                    'client_user_id' => ['No client account available for a test call. Pass client_user_id.'],
                ]);
            }
        } else {
            $client = $user;
            $proId = $data['professional_user_id'] ?? null;
            if (! $proId) {
                throw ValidationException::withMessages([
                    'professional_user_id' => ['Pick a professional for the test call.'],
                ]);
            }
            $pro = User::where('id', $proId)->where('role', 'professional')->first();
            if (! $pro) {
                throw ValidationException::withMessages([
                    'professional_user_id' => ['That user is not a professional.'],
                ]);
            }
        }

        if ((int) $client->id === (int) $pro->id) {
            throw ValidationException::withMessages([
                'peer' => ['Client and professional must be different accounts.'],
            ]);
        }

        $profile = ProfessionalProfile::where('user_id', $pro->id)->first();
        if (! $profile) {
            throw ValidationException::withMessages([
                'professional_user_id' => ['Professional has no profile yet.'],
            ]);
        }

        // One minute ago so join window is open on both apps immediately.
        $appt = Appointment::create([
            'user_id' => $client->id,
            'professional_user_id' => $pro->id,
            'professional_profile_id' => $profile->id,
            'scheduled_at' => now()->subMinute(),
            'duration_minutes' => 45,
            'session_type' => 'video',
            'status' => 'confirmed',
            'price_cents' => 0,
            'currency' => $profile->currency ?? 'USD',
            'user_timezone' => $client->timezone ?? 'UTC',
            'professional_timezone' => $pro->timezone ?? 'UTC',
            'confirmed_at' => now(),
        ]);

        $appt->load(['client', 'professional']);

        return response()->json([
            'message' => 'Free test call ready — both sides can Join now.',
            'appointment' => (new AppointmentResource($appt))->toArray($request),
            'appointment_id' => $appt->id,
            'client_email' => $client->email,
            'professional_email' => $pro->email,
        ], 201);
    }
}
