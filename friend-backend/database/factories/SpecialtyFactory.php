<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Specialty;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Specialty>
 */
class SpecialtyFactory extends Factory
{
    protected $model = Specialty::class;

    public function definition(): array
    {
        $name = fake()->unique()->word() . ' ' . fake()->word();
        return [
            'category_id' => Category::factory(),
            'slug'        => \Illuminate\Support\Str::slug($name),
            'name'        => ucwords($name),
            'is_active'   => true,
        ];
    }
}