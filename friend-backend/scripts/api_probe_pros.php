<?php
// Attempt live API login + list professionals (public after auth for some routes)
$base = 'http://13.140.131.249/api';

function req(string $method, string $url, ?array $body = null, ?string $token = null): array {
    $ch = curl_init($url);
    $headers = ['Accept: application/json', 'Content-Type: application/json'];
    if ($token) $headers[] = 'Authorization: Bearer '.$token;
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_POSTFIELDS => $body !== null ? json_encode($body) : null,
    ]);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err = curl_error($ch);
    curl_close($ch);
    return [$code, $raw, $err];
}

[$c, $raw, $err] = req('GET', $base.'/professionals');
echo "pros_public=$c err=$err\n";
echo substr((string)$raw, 0, 400)."\n\n";

foreach ([
    ['admin@akilil.app', 'changeme-9k2x'],
    ['admin@akilil.app', 'password'],
    ['admin@akilil.com', 'password'],
] as [$email, $pass]) {
    [$c, $raw] = req('POST', $base.'/auth/login', ['email' => $email, 'password' => $pass]);
    echo "login $email => $c ".substr((string)$raw, 0, 180)."\n";
}
