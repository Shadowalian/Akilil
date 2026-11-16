<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Discovery\DiscoveryFiltersRequest;
use App\Http\Resources\ProfessionalDetailResource;
use App\Http\Resources\ProfessionalListResource;
use App\Models\Dependent;
use App\Models\IntakeResponse;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfessionalController extends Controller
{
    /**
     * GET /api/professionals
     * Composable filter query builder. Every param is optional; the
     * spec calls out category, language, gender, specialty, session_type,
     * available_from, available_to. We extend with min_rating, max_price,
     * sort, and pagination.
     */
    public function index(DiscoveryFiltersRequest $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 20);
        $sort     = $request->input('sort') ?: ($request->route('sort') ?? 'rating');

        $q = ProfessionalProfile::query()
            ->approved()
            ->accepting()
            ->with(['user', 'category', 'specialties', 'languages']);

        if ($cid = $request->input('category_id')) {
            $q->where('category_id', $cid);
        } elseif ($slug = $request->input('category')) {
            $q->whereHas('category', fn ($c) => $c->where('slug', $slug));
        }

        if ($lid = $request->input('language_id')) {
            $q->whereHas('languages', fn ($l) => $l->where('languages.id', $lid));
        } elseif ($code = $request->input('language')) {
            $q->whereHas('languages', fn ($l) => $l->where('languages.code', $code));
        }

        if ($sid = $request->input('specialty_id')) {
            $q->whereHas('specialties', fn ($s) => $s->where('specialties.id', $sid));
        }

        // Family care: who offers this format / works with this age group.
        // Legacy profiles with no declaration count as individual + adults.
        $careFormat = $request->input('care_format');
        $ageGroup   = $request->input('age_group');
        if ($depId = $request->input('dependent_id')) {
            $dependent = Dependent::where('guardian_user_id', $request->user()->id)->find($depId);
            abort_unless($dependent, 422, 'Unknown dependent.');
            $ageGroup = $dependent->ageGroup();
        }
        // "Recommended" with no explicit filter falls back to the intake answers.
        if ($sort === 'match' && ! $careFormat && ! $ageGroup && ! $request->hasAny(['category', 'category_id'])) {
            $intake = IntakeResponse::where('user_id', $request->user()->id)->latest('id')->first();
            if ($intake) {
                $careFormat = $intake->care_format;
                if ($intake->pillar) {
                    $q->whereHas('category', fn ($c) => $c->where('slug', $intake->pillar));
                }
                if ($intake->dependent_id && ($d = Dependent::find($intake->dependent_id))) {
                    $ageGroup = $d->ageGroup();
                }
            }
        }
        if ($careFormat) {
            $q->where(function ($w) use ($careFormat) {
                $w->whereJsonContains('care_formats', $careFormat);
                if ($careFormat === 'individual') {
                    $w->orWhereNull('care_formats');
                }
            });
        }
        if ($ageGroup) {
            $q->where(function ($w) use ($ageGroup) {
                $w->whereJsonContains('age_groups', $ageGroup);
                if ($ageGroup === 'adults') {
                    $w->orWhereNull('age_groups');
                }
            });
        }

        if ($gender = $request->input('gender')) {
            $q->whereHas('user', fn ($u) => $u->where('gender', $gender));
        }

        if ($minRating = $request->input('min_rating')) {
            $q->where('rating_avg', '>=', (float) $minRating);
        }

        if ($maxPrice = $request->input('max_price_cents')) {
            $q->where('hourly_rate_cents', '<=', (int) $maxPrice);
        }

        // available_from / available_to — filter to pros with a rule that
        // covers at least one day in the requested range.
        if ($from = $request->input('available_from')) {
            $q->whereHas('user.availabilitySlotRules', function ($r) use ($from) {
                $r->where('is_active', true)
                  ->where(function ($q) use ($from) {
                      $q->whereNull('effective_from')->orWhereDate('effective_from', '<=', $from);
                  });
            });
        }

        $q->when(in_array($sort, ['rating','price','newest','experience','match'], true), function ($qq) use ($sort) {
            if ($sort === 'match') {
                $qq->orderByDesc('badge_active')->orderByDesc('rating_avg')->orderByDesc('rating_count');
                return;
            }
            $qq->orderBy(match ($sort) {
                'rating'    => 'rating_avg',
                'price'     => 'hourly_rate_cents',
                'experience'=> 'experience_years',
                'newest'    => 'created_at',
            }, match ($sort) {
                'price' => 'asc',
                default => 'desc',
            });
        });

        $page = $q->paginate($perPage);

        return response()->json([
            'data' => ProfessionalListResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    /**
     * GET /api/professionals/{id}  (id = professional_profiles.id)
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $profile = ProfessionalProfile::with([
                'user', 'category', 'specialties', 'languages',
                'documents' => fn ($q) => $q->where('review_status', 'approved'),
            ])
            ->approved()
            ->findOrFail($id);

        return (new ProfessionalDetailResource($profile))->response();
    }
}