<?php

use App\Models\User;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = User::updateOrCreate(
    ['email' => 'demo@akilil.app'],
    [
        'name' => 'Demo User',
        'password' => Hash::make('CandyPass1'),
        'role' => 'user',
        'email_verified_at' => now(),
    ]
);

echo "demo user id={$user->id} email={$user->email}\n";
