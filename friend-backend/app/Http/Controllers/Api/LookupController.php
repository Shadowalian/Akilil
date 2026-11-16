<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Language;
use App\Models\Specialty;
use Illuminate\Http\JsonResponse;

/**
 * Reference data the apps need to render pickers (categories, specialties,
 * languages). Read-only, seeded by the admin side.
 */
class LookupController extends Controller
{
    /**
     * GET /api/categories
     */
    public function categories(): JsonResponse
    {
        $categories = Category::where('is_active', true)->orderBy('sort_order')->get();

        return response()->json([
            'data' => $categories->map(fn ($c) => [
                'id'   => $c->id,
                'slug' => $c->slug,
                'name' => $c->name,
            ]),
        ]);
    }

    /**
     * GET /api/specialties
     */
    public function specialties(): JsonResponse
    {
        $specialties = Specialty::orderBy('name')->get();

        return response()->json([
            'data' => $specialties->map(fn ($s) => [
                'id'          => $s->id,
                'slug'        => $s->slug,
                'name'        => $s->name,
                'category_id' => $s->category_id,
            ]),
        ]);
    }

    /**
     * GET /api/languages
     */
    public function languages(): JsonResponse
    {
        $languages = Language::orderBy('name')->get();

        return response()->json([
            'data' => $languages->map(fn ($l) => [
                'id'   => $l->id,
                'code' => $l->code,
                'name' => $l->name,
            ]),
        ]);
    }
}
