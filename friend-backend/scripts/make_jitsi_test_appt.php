<?php

use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\User;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$client = User::where('email', 'demo@akilil.app')->first()
    ?? User::where('role', 'user')->where('email', 'not like', '%@akilil.app')->first()
    ?? User::where('role', 'user')->skip(3)->firstOrFail();

$pro = User::where('role', 'professional')->firstOrFail();
$profile = ProfessionalProfile::where('user_id', $pro->id)->firstOrFail();

$appt = Appointment::create([
    'user_id' => $client->id,
    'professional_user_id' => $pro->id,
    'professional_profile_id' => $profile->id,
    'scheduled_at' => now()->addMinutes(5),
    'duration_minutes' => 45,
    'session_type' => 'video',
    'status' => 'confirmed',
    'price_cents' => 5000,
    'currency' => 'USD',
    'user_timezone' => 'UTC',
    'professional_timezone' => 'UTC',
]);

$token = $client->createToken('jitsi-check')->plainTextToken;
echo "EMAIL={$client->email}\nAPPT={$appt->id}\nTOKEN={$token}\n";
