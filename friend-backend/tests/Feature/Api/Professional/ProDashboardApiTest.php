<?php

namespace Tests\Feature\Api\Professional;

use App\Models\Appointment;
use App\Models\Category;
use App\Models\ProfessionalDocument;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProDashboardApiTest extends TestCase
{
    use RefreshDatabase;

    private User $pro;
    private User $client;
    private ProfessionalProfile $profile;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pro    = User::factory()->create(['role' => 'professional']);
        $this->client = User::factory()->create(['role' => 'user']);

        $this->profile = ProfessionalProfile::factory()->approved()->create([
            'user_id'     => $this->pro->id,
            'category_id' => Category::factory()->create(['is_active' => true])->id,
        ]);
    }

    private function proToken(): string
    {
        return $this->pro->createToken('test')->plainTextToken;
    }

    private function makeAppointment(array $attributes = []): Appointment
    {
        return Appointment::factory()->create(array_merge([
            'user_id'                 => $this->client->id,
            'professional_user_id'    => $this->pro->id,
            'professional_profile_id' => $this->profile->id,
            'scheduled_at'            => now()->subDay(),
            'status'                  => 'completed',
            'price_cents'             => 4500,
            'currency'                => 'USD',
        ], $attributes));
    }

    public function test_professional_can_list_their_own_appointments(): void
    {
        $this->makeAppointment();
        // Another pro's session must not leak into the list.
        $otherPro = User::factory()->create(['role' => 'professional']);
        $otherProfile = ProfessionalProfile::factory()->approved()->create([
            'user_id'     => $otherPro->id,
            'category_id' => Category::factory()->create()->id,
        ]);
        $this->makeAppointment([
            'professional_user_id'    => $otherPro->id,
            'professional_profile_id' => $otherProfile->id,
            'scheduled_at'            => now()->subDays(2),
        ]);

        $res = $this->withToken($this->proToken())->getJson('/api/professional/appointments');

        $res->assertOk()
            ->assertJsonStructure(['data', 'meta' => ['current_page', 'last_page', 'per_page', 'total']])
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.professional_user_id', $this->pro->id);
    }

    public function test_client_cannot_list_professional_appointments(): void
    {
        $token = $this->client->createToken('test')->plainTextToken;
        $this->withToken($token)->getJson('/api/professional/appointments')->assertForbidden();
    }

    public function test_earnings_summary_returns_total_and_series(): void
    {
        $this->makeAppointment(['price_cents' => 4500, 'scheduled_at' => now()->subDays(2)]);
        $this->makeAppointment(['price_cents' => 5500, 'scheduled_at' => now()->subDay(), 'status' => 'confirmed']);
        // Outside the window — must not count.
        $this->makeAppointment(['price_cents' => 9900, 'scheduled_at' => now()->subDays(30)]);

        $res = $this->withToken($this->proToken())->getJson('/api/professional/earnings/summary?days=7');

        $res->assertOk()
            ->assertJsonPath('total_cents', 10000)
            ->assertJsonPath('currency', 'USD')
            ->assertJsonCount(7, 'series')
            ->assertJsonStructure(['total_cents', 'currency', 'series' => [['date', 'cents']]]);
    }

    public function test_clients_list_groups_appointments_by_user(): void
    {
        $this->makeAppointment(['scheduled_at' => now()->subDays(3)]);
        $this->makeAppointment(['scheduled_at' => now()->subDay()]);

        $res = $this->withToken($this->proToken())->getJson('/api/professional/clients');

        $res->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user.id', $this->client->id)
            ->assertJsonPath('data.0.session_count', 2);
    }

    public function test_professional_can_update_their_profile_bio(): void
    {
        $res = $this->withToken($this->proToken())->putJson('/api/me/professional-profile', [
            'bio'         => 'I help people sleep at night.',
            'headline'    => 'ignored field',
            'category_id' => Category::first()->slug,
        ]);

        $res->assertOk()->assertJsonPath('bio', 'I help people sleep at night.');
        $this->assertDatabaseHas('professional_profiles', [
            'user_id' => $this->pro->id,
            'bio'     => 'I help people sleep at night.',
        ]);
    }

    public function test_availability_blocks_endpoint_returns_only_blocks(): void
    {
        $this->pro->availabilityBlocks()->create([
            'start_at' => now()->addDay(),
            'end_at'   => now()->addDays(2),
            'reason'   => 'Travel',
        ]);

        $this->withToken($this->proToken())->getJson('/api/professional/availability/blocks')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.reason', 'Travel');
    }

    public function test_payout_can_be_requested_and_listed(): void
    {
        $this->withToken($this->proToken())->postJson('/api/professional/payouts', [
            'amount_cents' => 25000,
        ])->assertCreated()->assertJsonPath('display_status', 'requested');

        $this->withToken($this->proToken())->postJson('/api/professional/payouts', [
            'amount_cents' => 100,
        ])->assertStatus(422);

        $this->withToken($this->proToken())->getJson('/api/professional/payouts')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount_cents', 25000);
    }

    public function test_categories_lookup_is_available(): void
    {
        $this->withToken($this->proToken())->getJson('/api/categories')
            ->assertOk()
            ->assertJsonStructure(['data' => [['id', 'slug', 'name']]]);
    }

    public function test_media_is_forbidden_for_another_users_document(): void
    {
        $document = $this->fakeDocumentOfAnotherProfessional();

        $this->withToken($this->proToken())->getJson('/api/media/'.$document->file_path)->assertForbidden();
    }

    public function test_media_is_served_to_the_document_owner(): void
    {
        $document = $this->fakeDocumentOfAnotherProfessional();

        $ownerToken = $document->user->createToken('test')->plainTextToken;
        $this->withToken($ownerToken)->get('/api/media/'.$document->file_path)->assertOk();
    }

    private function fakeDocumentOfAnotherProfessional(): ProfessionalDocument
    {
        Storage::fake(config('filesystems.private_disk', 'local'));

        $otherPro = User::factory()->create(['role' => 'professional']);
        $path     = "professionals/{$otherPro->id}/documents/license.pdf";
        Storage::disk(config('filesystems.private_disk', 'local'))->put($path, 'pdf-bytes');

        return ProfessionalDocument::create([
            'user_id'           => $otherPro->id,
            'document_type'     => 'professional_license',
            'file_path'         => $path,
            'original_filename' => 'license.pdf',
            'size_bytes'        => 9,
            'mime_type'         => 'application/pdf',
            'review_status'     => 'pending',
        ]);
    }
}
