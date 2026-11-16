<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Rating\StoreReviewRequest;
use App\Http\Resources\RatingReviewResource;
use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\RatingReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RatingController extends Controller
{
    /**
     * POST /api/appointments/{id}/reviews
     * Only the client of a completed session may review it, once. The
     * professional's aggregate is recomputed from the visible reviews rather
     * than incremented, so moderation actions stay in sync.
     */
    public function store(StoreReviewRequest $request, int $appointmentId): JsonResponse
    {
        $user = $request->user();
        $appt = Appointment::findOrFail($appointmentId);

        abort_unless($appt->user_id === $user->id, 403, 'Only the client can review this session.');

        if ($appt->status !== 'completed') {
            throw ValidationException::withMessages([
                'status' => ['Only completed sessions can be reviewed.'],
            ]);
        }
        if (RatingReview::where('appointment_id', $appt->id)->exists()) {
            throw ValidationException::withMessages([
                'appointment_id' => ['This session has already been reviewed.'],
            ]);
        }

        $data = $request->validated();

        $review = DB::transaction(function () use ($appt, $user, $data) {
            $review = RatingReview::create([
                'appointment_id'       => $appt->id,
                'client_user_id'       => $user->id,
                'professional_user_id' => $appt->professional_user_id,
                'rating'               => $data['rating'],
                'comment'              => $data['comment'] ?? null,
                'is_anonymous'         => $data['is_anonymous'] ?? false,
                'status'               => 'visible',
            ]);

            $this->recomputeProfessionalRating($appt->professional_user_id);

            return $review;
        });

        return response()->json((new RatingReviewResource($review))->toArray($request), 201);
    }

    /**
     * GET /api/professionals/{id}/reviews  (id = professional_profiles.id)
     */
    public function index(Request $request, int $professionalProfileId): JsonResponse
    {
        $profile = ProfessionalProfile::findOrFail($professionalProfileId);

        $page = RatingReview::where('professional_user_id', $profile->user_id)
            ->where('status', 'visible')
            ->with('client')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => RatingReviewResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page'  => $page->currentPage(),
                'last_page'     => $page->lastPage(),
                'per_page'      => $page->perPage(),
                'total'         => $page->total(),
                'rating_avg'    => (float) $profile->rating_avg,
                'rating_count'  => (int) $profile->rating_count,
            ],
        ]);
    }

    private function recomputeProfessionalRating(int $professionalUserId): void
    {
        $aggregate = RatingReview::where('professional_user_id', $professionalUserId)
            ->where('status', 'visible')
            ->selectRaw('COUNT(*) as reviews_count, AVG(rating) as reviews_avg')
            ->first();

        ProfessionalProfile::where('user_id', $professionalUserId)->update([
            'rating_count' => (int) $aggregate->reviews_count,
            'rating_avg'   => round((float) $aggregate->reviews_avg, 2),
        ]);
    }
}
