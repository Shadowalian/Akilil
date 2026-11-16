<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    protected $model = Category::class;

    public function definition(): array
    {
        $name = fake()->unique()->word() . ' ' . fake()->word();
        return [
            'slug'        => \Illuminate\Support\Str::slug($name),
            'name'        => ucwords($name),
            'description' => fake()->sentence(),
            'icon'        => 'sparkle',
            'sort_order'  => fake()->numberBetween(0, 100),
            'is_active'   => true,
        ];
    }
}