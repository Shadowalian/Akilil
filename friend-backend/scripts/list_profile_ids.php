<?php
/**
 * Hide every approved professional on the live server by editing Filament
 * forms: verification_status=rejected, is_accepting_clients=0.
 *
 * Uses a Sanctum admin token is NOT enough — profiles aren't API-updatable.
 * Instead this script drives Filament's session + Livewire is too heavy;
 * we soft-fail and print IDs for the browser agent.
 *
 * Primary path: list profile IDs for the wipe loop.
 */
$base = 'http://13.140.131.249/api';
$ch = curl_init($base.'/auth/login');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => ['Accept: application/json', 'Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode(['email' => 'admin@akilil.app', 'password' => 'changeme-9k2x']),
]);
$login = json_decode(curl_exec($ch), true);
curl_close($ch);
$token = $login['token'] ?? '';

$ch = curl_init($base.'/professionals?per_page=50');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Accept: application/json', 'Authorization: Bearer '.$token],
]);
$data = json_decode(curl_exec($ch), true);
curl_close($ch);

$ids = array_map(fn ($p) => (int) $p['id'], $data['data'] ?? []);
echo implode(',', $ids), PHP_EOL;
file_put_contents(__DIR__.'/pro_profile_ids.txt', implode("\n", $ids));
