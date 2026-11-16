<?php

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

foreach (App\Models\User::take(10)->get(['id', 'email', 'role']) as $u) {
    echo "{$u->id} {$u->email} {$u->role}\n";
}
echo 'count='.App\Models\User::count()."\n";
