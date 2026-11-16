<?php
$base = 'http://13.140.131.249/api';
$token = null;

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
    return [$code, json_decode((string) $raw, true), $raw];
}

[$c, $data] = req('POST', $base.'/auth/login', [
    'email' => 'admin@akilil.app',
    'password' => 'changeme-9k2x',
]);
$token = $data['token'] ?? null;
echo "admin_login=$c token=".($token ? 'yes' : 'no').PHP_EOL;

[$c, $data, $raw] = req('GET', $base.'/professionals?per_page=50', null, $token);
echo "pros_list=$c\n";
$items = $data['data'] ?? [];
echo 'count='.count($items).PHP_EOL;
foreach ($items as $p) {
    echo ($p['id'] ?? '?')."\t".($p['display_name'] ?? '')."\t".($p['verification_status'] ?? '')."\taccept=".(($p['is_accepting_clients'] ?? false) ? '1' : '0').PHP_EOL;
}
file_put_contents(__DIR__.'/pros_snapshot.json', json_encode($data, JSON_PRETTY_PRINT));
