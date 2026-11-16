<?php

namespace Database\Factories;

use App\Models\Language;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Language>
 */
class LanguageFactory extends Factory
{
    protected $model = Language::class;

    public function definition(): array
    {
        $languages = [
            ['en', 'English'], ['am', 'Amharic'], ['om', 'Afaan Oromoo'],
            ['ti', 'Tigrinya'], ['sw', 'Kiswahili'], ['fr', 'French'],
        ];
        [$code, $name] = fake()->unique()->randomElement($languages);
        return [
            'code'      => $code,
            'name'      => $name,
            'is_active' => true,
        ];
    }
}