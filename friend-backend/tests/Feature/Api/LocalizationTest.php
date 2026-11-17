<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LocalizationTest extends TestCase
{
    use RefreshDatabase;

    public function test_errors_are_english_by_default(): void
    {
        User::factory()->create(['email' => 'a@example.com']);

        $this->postJson('/api/auth/login', ['email' => 'a@example.com', 'password' => 'wrong-Pass-1'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'The provided credentials are incorrect.');
    }

    public function test_errors_follow_the_app_language(): void
    {
        User::factory()->create(['email' => 'a@example.com']);

        $this->postJson('/api/auth/login', ['email' => 'a@example.com', 'password' => 'wrong-Pass-1'], ['Accept-Language' => 'am'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'ኢሜይሉ ወይም የይለፍ ቃሉ ትክክል አይደለም።')
            ->assertJsonPath('message', 'ኢሜይሉ ወይም የይለፍ ቃሉ ትክክል አይደለም።');
    }

    public function test_validation_rules_are_translated(): void
    {
        $this->postJson('/api/auth/login', [], ['Accept-Language' => 'am'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'ኢሜይል ያስፈልጋል።');
    }

    public function test_unknown_languages_fall_back_to_english(): void
    {
        $this->postJson('/api/auth/login', [], ['Accept-Language' => 'fr-FR'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'The email field is required.');
    }
}
