<?php

namespace App\Http\Controllers\Api\Session;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Session\StoreSessionNoteRequest;
use App\Http\Resources\SessionNoteResource;
use App\Models\Appointment;
use App\Models\SessionNote;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SessionNoteController extends Controller
{
    /**
     * GET /api/appointments/{id}/notes
     * Private to the professional who ran the session — the client never
     * reads these through the API.
     */
    public function index(Request $request, int $appointmentId): JsonResponse
    {
        $appt = $this->ownedAppointment($request, $appointmentId);

        $notes = SessionNote::where('appointment_id', $appt->id)
            ->where('professional_user_id', $request->user()->id)
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'data' => SessionNoteResource::collection($notes)->resolve($request),
        ]);
    }

    /**
     * POST /api/appointments/{id}/notes
     */
    public function store(StoreSessionNoteRequest $request, int $appointmentId): JsonResponse
    {
        $appt = $this->ownedAppointment($request, $appointmentId);
        $data = $request->validated();

        $note = SessionNote::create([
            'appointment_id'       => $appt->id,
            'professional_user_id' => $request->user()->id,
            'client_user_id'       => $appt->user_id,
            'notes'                => $data['notes'],
            'action_items'         => $data['action_items'] ?? null,
        ]);

        return response()->json((new SessionNoteResource($note))->toArray($request), 201);
    }

    private function ownedAppointment(Request $request, int $appointmentId): Appointment
    {
        $appt = Appointment::findOrFail($appointmentId);
        abort_unless($appt->professional_user_id === $request->user()->id, 403, 'Not your session.');

        return $appt;
    }
}
