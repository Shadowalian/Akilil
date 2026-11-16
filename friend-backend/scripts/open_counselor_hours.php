<?php
/**
 * After counselors are approved, open Mon–Fri 09:00–17:00 availability
 * (Africa/Addis_Ababa) so BetterHelp-style booking has real slots.
 */
$base = 'http://13.140.131.249/api';
$counselors = json_decode(file_get_contents(__DIR__.'/betterhelp_counselors.json'), true);

function req(string $method, string $url, ?array $body = null, ?string $token = null): array {
    $ch = curl_init($url);
    $headers = ['Accept: application/json', 'Content-Type: application/json'];
    if ($token) $headers[] = 'Authorization: Bearer '.$token;
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_POSTFIELDS => $body !== null ? json_encode($body) : null,
    ]);
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$code, json_decode((string)$raw, true), (string)$raw];
}

foreach ($counselors as $c) {
    // Refresh token via login
    [$lc, $ld] = req('POST', "$base/auth/login", [
        'email' => $c['email'],
        'password' => $c['password'],
    ]);
    $token = $ld['token'] ?? null;
    echo "login {$c['email']} => $lc\n";
    if (!$token) {
        echo "skip\n";
        continue;
    }

    // weekdays 1=Mon .. 5=Fri (ISO in SlotService uses isoFormat E)
    for ($weekday = 1; $weekday <= 5; $weekday++) {
        [$code, $data, $raw] = req('POST', "$base/professional/availability/rules", [
            'weekday' => $weekday,
            'start_time' => '09:00',
            'end_time' => '17:00',
            'timezone' => 'Africa/Addis_Ababa',
            'slot_duration_minutes' => 45,
            'buffer_minutes' => 15,
            'is_active' => true,
        ], $token);
        echo "  rule weekday=$weekday => $code ".substr($raw, 0, 120)."\n";
    }
}

// Verify public discovery
[$ac, $ad] = req('POST', "$base/auth/login", [
    'email' => 'admin@akilil.app',
    'password' => 'changeme-9k2x',
]);
[$pc, $pd] = req('GET', "$base/professionals?per_page=20", null, $ad['token'] ?? null);
echo "public_pros=$pc count=".count($pd['data'] ?? [])."\n";
foreach (($pd['data'] ?? []) as $p) {
    echo "  ".$p['id']." ".$p['display_name']."\n";
}
