<?php

namespace Tests\Feature\Api\Family;

use App\Models\Appointment;
use App\Models\AppointmentParticipant;
use App\Models\Dependent;
use App\Models\Earning;
use App\Models\User;
use App\Notifications\SessionInviteNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\Support\BuildsWorld;
use Tests\TestCase;

class FamilyCareTest extends TestCase
{
    use BuildsWorld, RefreshDatabase;

    private function registration(array $overrides = []): array
    {
        return [
            'name' => 'Selam Bekele', 'email' => 'selam@example.com',
            'password' => 'Pass-word-9', 'password_confirmation' => 'Pass-word-9',
            'date_of_birth' => '1990-04-02', 'accept_terms' => true,
            ...$overrides,
        ];
    }

    private function child(User $guardian, string $dob): Dependent
    {
        return Dependent::create([
            'guardian_user_id' => $guardian->id, 'name' => 'Abel', 'date_of_birth' => $dob,
            'relationship' => 'parent', 'consent_version' => 'test', 'consent_accepted_at' => now(),
        ]);
    }

    /* ---- Sign-up age gate ---- */

    public function test_registration_asks_for_date_of_birth(): void
    {
        $this->postJson('/api/auth/register', $this->registration(['date_of_birth' => null]))
            ->assertStatus(422)->assertJsonValidationErrors('date_of_birth');
    }

    public function test_a_minor_cannot_sign_up_alone_and_is_pointed_to_a_guardian(): void
    {
        $this->postJson('/api/auth/register', $this->registration(['date_of_birth' => now()->subYears(15)->toDateString()]))
            ->assertStatus(422)->assertJsonPath('code', 'guardian_required');
        $this->assertDatabaseMissing('users', ['email' => 'selam@example.com']);
    }

    public function test_an_adult_signs_up_and_says_who_care_is_for(): void
    {
        $this->postJson('/api/auth/register', $this->registration(['seeking_care_for' => 'child']))
            ->assertCreated()
            ->assertJsonPath('user.seeking_care_for', 'child')
            ->assertJsonPath('user.is_minor', false)
            ->assertJsonPath('user.needs_date_of_birth', false);
    }

    public function test_date_of_birth_cannot_be_changed_once_set(): void
    {
        $user = $this->adult();
        $this->actingAs($user)->putJson('/api/me', ['date_of_birth' => '1970-01-01'])->assertOk();
        $this->assertSame('1990-01-01', $user->fresh()->date_of_birth->toDateString());
    }

    /* ---- Dependents ---- */

    public function test_guardian_adds_a_child_with_recorded_consent(): void
    {
        $guardian = $this->adult();
        $payload = ['name' => 'Abel', 'date_of_birth' => now()->subYears(9)->toDateString(), 'relationship' => 'parent'];

        $this->actingAs($guardian)->postJson('/api/dependents', $payload)
            ->assertStatus(422)->assertJsonValidationErrors('guardian_consent');

        $this->actingAs($guardian)->postJson('/api/dependents', [...$payload, 'guardian_consent' => true])
            ->assertCreated()
            ->assertJsonPath('dependent.age', 9)
            ->assertJsonPath('dependent.age_group', 'children')
            ->assertJsonPath('dependent.can_have_teen_login', false);

        $this->assertNotNull(Dependent::first()->consent_accepted_at);
    }

    public function test_a_dependent_must_be_under_18(): void
    {
        $this->actingAs($this->adult())->postJson('/api/dependents', [
            'name' => 'Grown', 'date_of_birth' => '1990-01-01', 'relationship' => 'parent', 'guardian_consent' => true,
        ])->assertStatus(422)->assertJsonValidationErrors('date_of_birth');
    }

    public function test_dependents_are_private_to_their_guardian(): void
    {
        $child = $this->child($this->adult(), now()->subYears(9)->toDateString());
        $stranger = $this->adult();

        $this->actingAs($stranger)->getJson('/api/dependents')->assertOk()->assertJsonCount(0, 'data');
        $this->actingAs($stranger)->putJson("/api/dependents/{$child->id}", ['name' => 'X'])->assertNotFound();
    }

    public function test_teen_login_is_guardian_managed_and_cannot_pay_or_book(): void
    {
        $guardian = $this->adult();
        $teenProfile = $this->child($guardian, now()->subYears(15)->toDateString());
        $pro = $this->pro('psychiatry', ['care_formats' => ['individual', 'teen'], 'age_groups' => ['adults', 'teens']]);

        $this->actingAs($guardian)->postJson("/api/dependents/{$teenProfile->id}/teen-login", [
            'email' => 'teen@example.com', 'password' => 'Pass-word-9', 'password_confirmation' => 'Pass-word-9',
        ])->assertCreated();

        $teen = User::where('email', 'teen@example.com')->firstOrFail();
        $this->assertSame($guardian->id, $teen->guardian_user_id);
        $this->assertTrue($teen->isMinor());

        $this->actingAs($teen)->postJson('/api/wallet/topup', ['amount_cents' => 5000])
            ->assertForbidden()->assertJsonPath('code', 'guardian_required');
        $this->actingAs($teen)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(),
        ])->assertForbidden()->assertJsonPath('code', 'guardian_required');

        // The guardian books and pays; the teen sees and can join it.
        $id = $this->actingAs($guardian)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'dependent_id' => $teenProfile->id,
        ])->assertCreated()->assertJsonPath('care_format', 'teen')->json('id');

        $this->actingAs($teen)->getJson('/api/appointments')->assertOk()->assertJsonPath('data.0.id', $id);
        $this->actingAs($teen)->getJson("/api/appointments/{$id}")->assertOk();
        $this->actingAs($teen)->putJson("/api/appointments/{$id}/cancel")->assertForbidden();
    }

    public function test_younger_children_do_not_get_their_own_login(): void
    {
        $guardian = $this->adult();
        $child = $this->child($guardian, now()->subYears(8)->toDateString());

        $this->actingAs($guardian)->postJson("/api/dependents/{$child->id}/teen-login", [
            'email' => 'kid@example.com', 'password' => 'Pass-word-9', 'password_confirmation' => 'Pass-word-9',
        ])->assertStatus(422);
    }

    /* ---- Booking for a child ---- */

    public function test_guardian_books_and_pays_for_their_child(): void
    {
        $guardian = $this->adult(20_000);
        $child = $this->child($guardian, now()->subYears(9)->toDateString());
        $pro = $this->pro('psychiatry', ['care_formats' => ['individual', 'child'], 'age_groups' => ['adults', 'children']]);

        $this->actingAs($guardian)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'dependent_id' => $child->id,
        ])->assertCreated()
            ->assertJsonPath('care_format', 'child')
            ->assertJsonPath('dependent.name', 'Abel')
            ->assertJsonPath('user_id', $guardian->id);

        $this->assertSame(15_000, $guardian->wallet->fresh()->balance_cents);
    }

    public function test_cannot_book_a_child_with_someone_who_only_sees_adults(): void
    {
        $guardian = $this->adult();
        $child = $this->child($guardian, now()->subYears(9)->toDateString());
        $adultsOnly = $this->pro();

        $this->actingAs($guardian)->postJson('/api/appointments', [
            'professional_user_id' => $adultsOnly->id, 'scheduled_at' => $this->slot(), 'dependent_id' => $child->id,
        ])->assertStatus(422)->assertJsonValidationErrors('care_format');
    }

    public function test_cannot_book_for_someone_elses_child(): void
    {
        $child = $this->child($this->adult(), now()->subYears(9)->toDateString());
        $pro = $this->pro('psychiatry', ['care_formats' => ['child'], 'age_groups' => ['children']]);

        $this->actingAs($this->adult())->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'dependent_id' => $child->id,
        ])->assertStatus(422)->assertJsonValidationErrors('dependent_id');
    }

    public function test_discovery_filters_by_care_format_and_child_age_group(): void
    {
        $guardian = $this->adult();
        $child = $this->child($guardian, now()->subYears(9)->toDateString());
        $couples = $this->pro('psychiatry', ['care_formats' => ['individual', 'couples'], 'age_groups' => ['adults']]);
        $childPro = $this->pro('psychiatry', ['care_formats' => ['child'], 'age_groups' => ['children']]);
        $legacy = $this->pro(); // no declaration → individual, adults

        $ids = fn (string $query) => collect(
            $this->actingAs($guardian)->getJson("/api/professionals?{$query}")->assertOk()->json('data')
        )->pluck('user_id')->all();

        $this->assertSame([$couples->id], $ids('care_format=couples'));
        $this->assertSame([$childPro->id], $ids("dependent_id={$child->id}"));
        $this->assertEqualsCanonicalizing([$couples->id, $legacy->id], $ids('care_format=individual'));
    }

    /* ---- Couples ---- */

    public function test_couples_counselling_invites_the_partner_who_joins_from_their_own_account(): void
    {
        Notification::fake();
        $me = $this->adult(20_000);
        $partner = $this->adult(0, ['email' => 'partner@example.com']);
        $stranger = $this->adult();
        $pro = $this->pro('psychiatry', ['care_formats' => ['individual', 'couples'], 'couples_rate_cents' => 8000]);

        // Couples needs a partner.
        $this->actingAs($me)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'care_format' => 'couples',
        ])->assertStatus(422)->assertJsonValidationErrors('participants');

        $id = $this->actingAs($me)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'care_format' => 'couples',
            'participants' => [['name' => 'Dawit', 'email' => 'Partner@Example.com']],
        ])->assertCreated()
            ->assertJsonPath('price_cents', 8000)        // couples rate, not the base rate
            ->assertJsonPath('participants.0.status', 'invited')
            ->json('id');

        Notification::assertSentOnDemand(SessionInviteNotification::class);
        $this->assertSame(12_000, $me->wallet->fresh()->balance_cents);   // one payer

        // Not in the room until they accept.
        $this->actingAs($partner)->getJson("/api/appointments/{$id}")->assertForbidden();
        $invite = $this->actingAs($partner)->getJson('/api/appointment-invites')->assertOk()->json('data.0');
        $this->assertSame($id, $invite['appointment_id']);

        // Someone else can't claim an invite addressed to the partner.
        $this->actingAs($stranger)->postJson('/api/appointment-invites/accept', ['invite_id' => $invite['id']])->assertNotFound();

        $this->actingAs($partner)->postJson('/api/appointment-invites/accept', ['invite_id' => $invite['id']])->assertOk();
        $this->actingAs($partner)->getJson("/api/appointments/{$id}")->assertOk();
        $this->actingAs($partner)->getJson('/api/appointments')->assertJsonPath('data.0.id', $id);

        // Free sessions skip the join window; make it joinable now.
        Appointment::whereKey($id)->update(['scheduled_at' => now()->addMinutes(5)]);
        $this->actingAs($partner)->postJson("/api/appointments/{$id}/session/start")
            ->assertOk()->assertJsonPath('session.is_host', false);
        $this->actingAs($stranger)->postJson("/api/appointments/{$id}/session/start")->assertForbidden();
    }

    public function test_an_emailed_invite_code_works_for_a_partner_with_a_different_email(): void
    {
        Notification::fake();
        $me = $this->adult();
        $partner = $this->adult();
        $pro = $this->pro('psychiatry', ['care_formats' => ['couples']]);

        $id = $this->actingAs($me)->postJson('/api/appointments', [
            'professional_user_id' => $pro->id, 'scheduled_at' => $this->slot(), 'care_format' => 'couples',
            'participants' => [['name' => 'Dawit', 'email' => 'someone-else@example.com']],
        ])->assertCreated()->json('id');

        $token = AppointmentParticipant::where('appointment_id', $id)->value('invite_token');
        $this->actingAs($partner)->postJson('/api/appointment-invites/accept', ['token' => $token])->assertOk();
        $this->actingAs($partner)->getJson("/api/appointments/{$id}")->assertOk();
    }

    public function test_a_professional_must_offer_couples_to_be_booked_for_it(): void
    {
        $this->actingAs($this->adult())->postJson('/api/appointments', [
            'professional_user_id' => $this->pro()->id, 'scheduled_at' => $this->slot(), 'care_format' => 'couples',
            'participants' => [['name' => 'Dawit']],
        ])->assertStatus(422)->assertJsonValidationErrors('care_format');
    }

    public function test_professional_declares_formats_consistently(): void
    {
        $pro = $this->pro();
        $this->actingAs($pro)->putJson('/api/me/professional-profile', [
            'care_formats' => ['individual', 'child'], 'age_groups' => ['adults'],
        ])->assertStatus(422)->assertJsonValidationErrors('age_groups');

        $this->actingAs($pro)->putJson('/api/me/professional-profile', [
            'care_formats' => ['individual', 'couples', 'family', 'child'], 'age_groups' => ['adults', 'children'],
            'couples_rate_cents' => 9000,
        ])->assertOk()->assertJsonPath('couples_rate_cents', 9000);
    }

    /* ---- Money: refunds and earnings ---- */

    public function test_cancelling_early_refunds_in_full_and_the_slot_can_be_rebooked(): void
    {
        $client = $this->adult(10_000);
        $pro = $this->pro();
        $slot = $this->slot(5);

        $id = $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $slot])
            ->assertCreated()->json('id');
        $this->assertSame(5_000, $client->wallet->fresh()->balance_cents);

        $this->actingAs($client)->putJson("/api/appointments/{$id}/cancel")
            ->assertOk()->assertJsonPath('refund_policy', 'full_refund')->assertJsonPath('refunded_cents', 5000);
        $this->assertSame(10_000, $client->wallet->fresh()->balance_cents);

        // Used to 500 on a unique index.
        $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $slot])->assertCreated();
    }

    public function test_late_cancellation_keeps_half_which_the_professional_earns(): void
    {
        $client = $this->adult(10_000);
        $pro = $this->pro();
        $id = $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $this->slot()])
            ->assertCreated()->json('id');
        Appointment::whereKey($id)->update(['scheduled_at' => now()->addHours(5)]);

        $this->actingAs($client)->putJson("/api/appointments/{$id}/cancel")->assertOk()->assertJsonPath('refunded_cents', 2500);

        $this->assertSame(7_500, $client->wallet->fresh()->balance_cents);
        $earning = Earning::where('professional_user_id', $pro->id)->firstOrFail();
        $this->assertSame([2500, 500, 2000], [$earning->gross_cents, $earning->fee_cents, $earning->net_cents]);
    }

    public function test_when_the_professional_cancels_the_client_always_gets_everything_back(): void
    {
        $client = $this->adult(10_000);
        $pro = $this->pro();
        $id = $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $this->slot()])
            ->assertCreated()->json('id');
        Appointment::whereKey($id)->update(['scheduled_at' => now()->addHour()]);

        $this->actingAs($pro)->putJson("/api/appointments/{$id}/cancel")->assertOk()->assertJsonPath('refunded_cents', 5000);
        $this->assertSame(10_000, $client->wallet->fresh()->balance_cents);
        $this->assertSame(0, Earning::count());
    }

    public function test_a_completed_session_becomes_withdrawable_earnings_net_of_the_fee(): void
    {
        $client = $this->adult();
        $pro = $this->pro();
        $id = $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $this->slot()])
            ->assertCreated()->json('id');
        Appointment::whereKey($id)->update(['scheduled_at' => now()->addMinutes(10)]);

        $this->actingAs($pro)->postJson("/api/appointments/{$id}/session/start")->assertOk();
        $this->actingAs($pro)->postJson("/api/appointments/{$id}/session/end")->assertOk();
        $this->actingAs($pro)->postJson("/api/appointments/{$id}/session/end")->assertOk();   // idempotent

        $this->assertSame(1, Earning::count());
        $this->actingAs($pro)->getJson('/api/professional/earnings/summary')
            ->assertOk()->assertJsonPath('available_cents', 4000)->assertJsonPath('fees_cents', 1000);

        // Can't withdraw more than was earned; can withdraw what was.
        $this->actingAs($pro)->postJson('/api/professional/payouts', ['amount_cents' => 4001])
            ->assertStatus(422)->assertJsonPath('code', 'insufficient_earnings');
        $this->actingAs($pro)->postJson('/api/professional/payouts', ['amount_cents' => 4000])->assertCreated();
        $this->actingAs($pro)->postJson('/api/professional/payouts', ['amount_cents' => 1000])->assertStatus(422);
    }

    /* ---- Demo shortcuts are off in production ---- */

    public function test_new_professionals_wait_for_verification_and_test_calls_are_disabled(): void
    {
        $this->postJson('/api/auth/register-professional', [
            'name' => 'Dr New', 'email' => 'new@example.com', 'password' => 'Pass-word-9', 'password_confirmation' => 'Pass-word-9',
            'category_id' => \App\Models\Category::factory()->create()->id,
        ])->assertCreated();
        $this->assertDatabaseHas('professional_profiles', ['verification_status' => 'pending', 'is_accepting_clients' => 0]);

        $this->actingAs($this->adult())->postJson('/api/appointments/test-call', ['professional_user_id' => $this->pro()->id])
            ->assertNotFound();
    }

    public function test_staff_cannot_join_a_private_session(): void
    {
        \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
        $admin = $this->adult();
        $admin->assignRole('admin');
        $client = $this->adult();
        $pro = $this->pro();
        $id = $this->actingAs($client)->postJson('/api/appointments', ['professional_user_id' => $pro->id, 'scheduled_at' => $this->slot()])->json('id');
        Appointment::whereKey($id)->update(['scheduled_at' => now()->addMinutes(10)]);

        $this->actingAs($admin)->postJson("/api/appointments/{$id}/session/start")->assertForbidden();
    }

    public function test_recommended_honours_intake_preferences_but_never_returns_nobody(): void
    {
        $me = $this->adult();
        $woman = $this->pro();
        $woman->update(['gender' => 'female']);
        $man = $this->pro();
        $man->update(['gender' => 'male']);

        $this->actingAs($me)->postJson('/api/intake', [
            'care_format' => 'individual', 'answers' => ['gender_preference' => 'female'],
        ])->assertCreated();
        $ids = collect($this->actingAs($me)->getJson('/api/professionals/recommended')->json('data'))->pluck('user_id')->all();
        $this->assertSame([$woman->id], $ids);

        // A preference nobody meets falls back to everyone.
        $this->actingAs($me)->postJson('/api/intake', [
            'care_format' => 'individual', 'answers' => ['languages' => ['ti']],
        ])->assertCreated();
        $this->assertCount(2, $this->actingAs($me)->getJson('/api/professionals/recommended')->json('data'));
    }
}
