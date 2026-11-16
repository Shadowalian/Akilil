<?php
/**
 * Soft-remove every professional from the live API by logging into Filament
 * and suspending each professional user (soft-delete).
 */
$base = 'http://13.140.131.249';
$cookieFile = sys_get_temp_dir().'/akilil_admin_cookies.txt';
@unlink($cookieFile);

function http(string $method, string $url, array $opts = []): array {
    global $cookieFile;
    $ch = curl_init($url);
    $headers = $opts['headers'] ?? ['Accept: text/html,application/xhtml+xml'];
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => false,
        CURLOPT_HEADER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_COOKIEJAR => $cookieFile,
        CURLOPT_COOKIEFILE => $cookieFile,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_POSTFIELDS => $opts['body'] ?? null,
    ]);
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);
    return [$code, substr((string)$raw, 0, $headerSize), substr((string)$raw, $headerSize)];
}

// 1) Login page for CSRF
[$c, $h, $b] = http('GET', $base.'/admin/login');
if (!preg_match('/name="_token" value="([^"]+)"/', $b, $m)) {
    // Filament v3 may use livewire / different token field
    if (!preg_match('/"csrf-token" content="([^"]+)"/', $b, $m) &&
        !preg_match("/csrfToken\\s*=\\s*'([^']+)'/", $b, $m) &&
        !preg_match('/X-CSRF-TOKEN" content="([^"]+)"/', $b, $m)) {
        fwrite(STDERR, "no csrf on login ($c)\n");
        file_put_contents(sys_get_temp_dir().'/login.html', $b);
        exit(1);
    }
}
$csrf = $m[1];
echo "csrf=$csrf login_page=$c\n";

[$c, $h, $b] = http('POST', $base.'/admin/login', [
    'headers' => [
        'Accept: text/html,application/xhtml+xml',
        'Content-Type: application/x-www-form-urlencoded',
    ],
    'body' => http_build_query([
        'email' => 'admin@akilil.app',
        'password' => 'changeme-9k2x',
        '_token' => $csrf,
    ]),
]);
echo "login_post=$c loc=".(preg_match('/^Location:\s*(.+)$/mi', $h, $lm) ? trim($lm[1]) : '')."\n";

// 2) API path: list pros and suspend via soft-delete using a Filament livewire call is hard.
// Instead: use Sanctum token + raw SQL through a temporary public endpoint we can't deploy.
// Fallback: use API login as each? No passwords.

// Try Filament users page to confirm session works
[$c, $h, $b] = http('GET', $base.'/admin/users');
echo "users_page=$c len=".strlen($b)." has_demo=".(str_contains($b, 'Demo Pro') ? 'yes' : 'no')."\n";
