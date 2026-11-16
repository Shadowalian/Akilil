<?php
$base = 'http://13.140.131.249/api';
function req($method, $url, $body = null, $token = null) {
    $ch = curl_init($url);
    $headers = ['Accept: application/json', 'Content-Type: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
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
    return [$code, json_decode((string)$raw, true)];
}

[$c, $login] = req('POST', "$base/auth/login", [
    'email' => 'admin@akilil.app',
    'password' => 'changeme-9k2x',
]);
$token = $login['token'];

// Pending pros won't show on public list. Use onboarding status or me endpoint per counselor.
$counselors = json_decode(file_get_contents(__DIR__.'/betterhelp_counselors.json'), true);
foreach ($counselors as $c) {
    $tok = $c['token'];
    [$code, $me] = req('GET', "$base/auth/me", null, $tok);
    if ($code !== 200) {
        [$code, $me] = req('GET', "$base/me", null, $tok);
    }
    echo "me {$c['email']} => $code ".substr(json_encode($me), 0, 250)."\n";
    [$code2, $st] = req('GET', "$base/professionals/onboarding/status", null, $tok);
    echo "onboarding => $code2 ".substr(json_encode($st), 0, 300)."\n";
}
