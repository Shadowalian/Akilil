<?php

namespace Tests\Feature\Api\Professional;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class OnboardingTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_user_cannot_view_onboarding_status(): void
    {
        $this->getJson('/api/professionals/onboarding/status')->assertUnauthorized();
    }

    public function test_end_user_cannot_view_onboarding_status(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/professionals/onboarding/status')
            ->assertForbidden();
    }

    public function test_professional_can_view_own_onboarding_status(): void
    {
        $cat = Category::factory()->create();
        $pro = User::factory()->create(['role' => 'professional']);
        $pro->professionalProfile()->create(['category_id' => $cat->id]);

        $token = $pro->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->getJson('/api/professionals/onboarding/status');
        $res->assertOk()
            ->assertJsonStructure(['profile', 'documents', 'progress', 'next_step'])
            ->assertJson(['progress' => ['badge_active' => false]]);
    }

    public function test_professional_can_upload_credential_document(): void
    {
        Storage::fake(config('filesystems.private_disk', 'local'));

        $cat = Category::factory()->create();
        $pro = User::factory()->create(['role' => 'professional']);
        $pro->professionalProfile()->create(['category_id' => $cat->id]);
        $token = $pro->createToken('test')->plainTextToken;

        $file = UploadedFile::fake()->create('license.pdf', 120, 'application/pdf');

        $res = $this->withToken($token)
            ->post('/api/professionals/onboarding/documents', [
                'document_type' => 'professional_license',
                'file'          => $file,
                'description'   => 'State license #ABC-123',
            ]);

        $res->assertCreated();
        $this->assertDatabaseHas('professional_documents', [
            'user_id'         => $pro->id,
            'document_type'   => 'professional_license',
            'review_status'   => 'pending',
        ]);
    }

    public function test_professional_can_register_via_endpoint(): void
    {
        $cat = Category::factory()->create(['slug' => 'therapy']);

        $res = $this->postJson('/api/auth/register-professional', [
            'name'              => 'Dr. Test',
            'email'             => 'pro@example.com',
            'password'          => 'ProPass-9',
            'password_confirmation' => 'ProPass-9',
            'category_id'       => $cat->id,
            'experience_years'  => 7,
            'bio'               => 'Helping people breathe.',
        ]);

        $res->assertCreated()->assertJsonStructure(['token', 'user']);
        $pro = User::where('email', 'pro@example.com')->first();
        $this->assertEquals('professional', $pro->role);
        $this->assertDatabaseHas('professional_profiles', [
            'user_id'             => $pro->id,
            'verification_status' => 'pending',
            'is_accepting_clients'=> 0,
        ]);
    }
}