<?php

namespace App\Http\Controllers\Api\Cooking;

use App\Http\Controllers\Controller;
use App\Http\Resources\RecipeResource;
use App\Models\IngredientChecklist;
use App\Models\Recipe;
use App\Models\User;
use App\Services\CookingRules;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Chef recipes: the ingredient list participants shop from before a
 * cooking session, and each participant's personal shopping checklist.
 */
class RecipeController extends Controller
{
    public function __construct(private CookingRules $cooking) {}

    /**
     * GET /api/recipes
     * Chefs: their own recipes (any status). Clients: published recipes,
     * optionally ?professional_user_id=.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = Recipe::query()->with('professional')->withCount('ingredients')->orderByDesc('id');

        $proId = $request->query('professional_user_id');
        if ($user->role === 'professional' && ! $proId) {
            $q->where('professional_user_id', $user->id);
            if ($status = $request->query('status')) {
                $q->where('status', $status);
            }
        } else {
            $q->published();
            if ($proId) {
                $q->where('professional_user_id', (int) $proId);
            }
        }

        $page = $q->paginate((int) $request->query('per_page', 30));

        return response()->json([
            'data' => RecipeResource::collection($page->items())->resolve($request),
            'meta' => ['current_page' => $page->currentPage(), 'last_page' => $page->lastPage(), 'total' => $page->total()],
        ]);
    }

    /** GET /api/recipes/{id} — published, or your own draft. */
    public function show(Request $request, int $id): JsonResponse
    {
        $recipe = Recipe::with(['professional', 'ingredients', 'steps'])->findOrFail($id);
        abort_unless(
            $recipe->isPublished() || $recipe->professional_user_id === $request->user()->id,
            404
        );

        return response()->json(['recipe' => (new RecipeResource($recipe))->toArray($request)]);
    }

    /** POST /api/recipes */
    public function store(Request $request): JsonResponse
    {
        $chef = $this->requireChef($request);
        $data = $request->validate($this->rules());

        $recipe = DB::transaction(function () use ($chef, $data) {
            $recipe = Recipe::create([
                ...$this->recipeFields($data),
                'professional_user_id' => $chef->id,
                'status' => 'draft',
            ]);
            $this->syncIngredients($recipe, $data['ingredients'] ?? []);
            $this->syncSteps($recipe, $data['steps'] ?? []);

            return $recipe;
        });

        if ($request->boolean('publish')) {
            $this->publishOrFail($recipe);
        }

        return response()->json(['recipe' => $this->full($recipe, $request)], 201);
    }

    /** PUT /api/recipes/{id} */
    public function update(Request $request, int $id): JsonResponse
    {
        $recipe = $this->owned($request, $id);
        $data = $request->validate($this->rules(partial: true));

        if (array_key_exists('ingredients', $data) && $this->cooking->recipeIsLocked($recipe)) {
            throw ValidationException::withMessages([
                'ingredients' => ['A session using this recipe starts soon and people have already shopped. Ingredients are locked until it ends.'],
            ]);
        }

        DB::transaction(function () use ($recipe, $data) {
            $recipe->update($this->recipeFields($data));
            if (array_key_exists('ingredients', $data)) {
                $this->syncIngredients($recipe, $data['ingredients']);
            }
            if (array_key_exists('steps', $data)) {
                $this->syncSteps($recipe, $data['steps']);
            }
        });

        if ($request->boolean('publish')) {
            $this->publishOrFail($recipe);
        }

        return response()->json(['recipe' => $this->full($recipe, $request)]);
    }

    /** POST /api/recipes/{id}/publish */
    public function publish(Request $request, int $id): JsonResponse
    {
        $recipe = $this->owned($request, $id);
        $this->publishOrFail($recipe);

        return response()->json(['recipe' => $this->full($recipe, $request)]);
    }

    /** POST /api/recipes/{id}/archive */
    public function archive(Request $request, int $id): JsonResponse
    {
        $recipe = $this->owned($request, $id);
        abort_if($this->cooking->recipeInUse($recipe), 422, 'This recipe is attached to an upcoming session. Finish or cancel it first.');
        $recipe->update(['status' => 'archived']);

        return response()->json(['recipe' => $this->full($recipe, $request)]);
    }

    /** DELETE /api/recipes/{id} */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $recipe = $this->owned($request, $id);
        abort_if($this->cooking->recipeInUse($recipe), 422, 'This recipe is attached to an upcoming session. Finish or cancel it first.');
        $recipe->delete();

        return response()->json(['message' => 'Recipe deleted.']);
    }

    /** GET /api/recipes/{id}/checklist — my ticks for this recipe's shopping list. */
    public function checklist(Request $request, int $id): JsonResponse
    {
        $recipe = Recipe::with('ingredients')->published()->findOrFail($id);

        return response()->json($this->checklistPayload($recipe, $request->user()));
    }

    /** PUT /api/recipes/{id}/checklist  { checked_ingredient_ids: [1,2,3] } */
    public function updateChecklist(Request $request, int $id): JsonResponse
    {
        $recipe = Recipe::with('ingredients')->published()->findOrFail($id);
        $data = $request->validate([
            'checked_ingredient_ids'   => ['present', 'array'],
            'checked_ingredient_ids.*' => ['integer'],
        ]);

        $valid = $recipe->ingredients->pluck('id')->all();
        IngredientChecklist::updateOrCreate(
            ['user_id' => $request->user()->id, 'recipe_id' => $recipe->id],
            ['checked_ingredient_ids' => array_values(array_intersect($valid, $data['checked_ingredient_ids']))],
        );

        return response()->json($this->checklistPayload($recipe, $request->user()));
    }

    /* ------------------------------------------------------------------ */

    private function checklistPayload(Recipe $recipe, User $user): array
    {
        $checked = IngredientChecklist::where('user_id', $user->id)
            ->where('recipe_id', $recipe->id)
            ->value('checked_ingredient_ids') ?? [];
        $checked = is_string($checked) ? (json_decode($checked, true) ?: []) : $checked;

        $required = $recipe->ingredients->where('is_optional', false)->pluck('id');
        $missing = $required->diff($checked)->values();

        return [
            'recipe_id' => $recipe->id,
            'checked_ingredient_ids' => array_values($checked),
            'missing_required_ids'   => $missing->all(),
            'is_complete'            => $missing->isEmpty(),
        ];
    }

    private function requireChef(Request $request): User
    {
        $user = $request->user();
        $profile = $user->professionalProfile()->with('category')->first();
        abort_unless($user->role === 'professional' && $profile?->isCookingPillar(), 403, 'Only chefs can manage recipes.');

        return $user;
    }

    private function owned(Request $request, int $id): Recipe
    {
        return Recipe::where('professional_user_id', $request->user()->id)->findOrFail($id);
    }

    private function publishOrFail(Recipe $recipe): void
    {
        $recipe->loadCount(['ingredients', 'steps']);
        if ($recipe->ingredients_count < 1) {
            throw ValidationException::withMessages(['ingredients' => ['Add at least one ingredient before publishing.']]);
        }
        if ($recipe->steps_count < 1) {
            throw ValidationException::withMessages(['steps' => ['Add at least one step before publishing.']]);
        }
        $recipe->update(['status' => 'published', 'published_at' => $recipe->published_at ?? now()]);
    }

    private function full(Recipe $recipe, Request $request): array
    {
        return (new RecipeResource($recipe->fresh()->load(['professional', 'ingredients', 'steps'])))->toArray($request);
    }

    private function recipeFields(array $data): array
    {
        return collect($data)->only([
            'title', 'description', 'cuisine', 'difficulty', 'prep_minutes', 'cook_minutes',
            'servings', 'cover_image_path', 'dietary_tags', 'allergens', 'equipment',
        ])->all();
    }

    private function rules(bool $partial = false): array
    {
        $req = $partial ? 'sometimes' : 'required';

        return [
            'title'         => [$req, 'string', 'min:2', 'max:160'],
            'description'   => ['sometimes', 'nullable', 'string', 'max:5000'],
            'cuisine'       => ['sometimes', 'nullable', 'string', 'max:64'],
            'difficulty'    => ['sometimes', 'in:easy,medium,hard'],
            'prep_minutes'  => ['sometimes', 'integer', 'min:0', 'max:1440'],
            'cook_minutes'  => ['sometimes', 'integer', 'min:0', 'max:1440'],
            'servings'      => ['sometimes', 'integer', 'min:1', 'max:100'],
            'cover_image_path' => ['sometimes', 'nullable', 'string', 'max:512'],
            'dietary_tags'  => ['sometimes', 'array', 'max:12'],
            'dietary_tags.*' => ['string', 'max:32'],
            'allergens'     => ['sometimes', 'array', 'max:20'],
            'allergens.*'   => ['string', 'max:32'],
            'equipment'     => ['sometimes', 'array', 'max:30'],
            'equipment.*'   => ['string', 'max:64'],

            'ingredients'   => ['sometimes', 'array', 'max:80'],
            'ingredients.*.name'        => ['required', 'string', 'max:160'],
            'ingredients.*.quantity'    => ['nullable', 'string', 'max:32'],
            'ingredients.*.unit'        => ['nullable', 'string', 'max:32'],
            'ingredients.*.note'        => ['nullable', 'string', 'max:255'],
            'ingredients.*.substitute'  => ['nullable', 'string', 'max:255'],
            'ingredients.*.is_optional' => ['nullable', 'boolean'],

            'steps'         => ['sometimes', 'array', 'max:60'],
            'steps.*.instruction'      => ['required', 'string', 'max:2000'],
            'steps.*.duration_minutes' => ['nullable', 'integer', 'min:0', 'max:1440'],
        ];
    }

    private function syncIngredients(Recipe $recipe, array $rows): void
    {
        $recipe->ingredients()->delete();
        foreach (array_values($rows) as $i => $row) {
            $recipe->ingredients()->create([
                'name'        => $row['name'],
                'quantity'    => $row['quantity'] ?? null,
                'unit'        => $row['unit'] ?? null,
                'note'        => $row['note'] ?? null,
                'substitute'  => $row['substitute'] ?? null,
                'is_optional' => (bool) ($row['is_optional'] ?? false),
                'sort_order'  => $i,
            ]);
        }
    }

    private function syncSteps(Recipe $recipe, array $rows): void
    {
        $recipe->steps()->delete();
        foreach (array_values($rows) as $i => $row) {
            $recipe->steps()->create([
                'position'    => $i + 1,
                'instruction' => $row['instruction'],
                'duration_minutes' => $row['duration_minutes'] ?? null,
            ]);
        }
    }
}
