<?php
/**
 * Create 3 BetterHelp-style counselors on the live API (pending),
 * print profile IDs for Filament approve + credentials for availability.
 */
$base = 'http://13.140.131.249/api';

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

$counselors = [
    [
        'name' => 'Dr. Sara Mekonnen',
        'email' => 'sara.mekonnen@akilil.app',
        'password' => 'AkililCare1!',
        'password_confirmation' => 'AkililCare1!',
        'category_id' => 2, // Psychiatry
        'experience_years' => 12,
        'bio' => 'Licensed psychiatrist with a calm, structured style. I help adults with anxiety, depression, and life transitions — in English or Amharic. Sessions are private video meetings.',
        'timezone' => 'Africa/Addis_Ababa',
        'locale' => 'en',
    ],
    [
        'name' => 'Helen Tadesse',
        'email' => 'helen.tadesse@akilil.app',
        'password' => 'AkililCare1!',
        'password_confirmation' => 'AkililCare1!',
        'category_id' => 1, // Spiritual Psychiatry
        'experience_years' => 8,
        'bio' => 'Faith-aware counselor blending clinical skills with spiritual care. Specializes in grief, stress, and finding meaning — warm and non-judgmental.',
        'timezone' => 'Africa/Addis_Ababa',
        'locale' => 'en',
    ],
    [
        'name' => 'Chef Yonas Bekele',
        'email' => 'yonas.bekele@akilil.app',
        'password' => 'AkililCare1!',
        'password_confirmation' => 'AkililCare1!',
        'category_id' => 3, // Cooking
        'experience_years' => 10,
        'bio' => 'Chef-led live cooking sessions for nourishing weeknight meals. Learn simple, healthy Ethiopian and global dishes in a supportive kitchen class.',
        'timezone' => 'Africa/Addis_Ababa',
        'locale' => 'en',
    ],
];

$created = [];
foreach ($counselors as $c) {
    [$code, $data, $raw] = req('POST', $base.'/auth/register-professional', $c);
    echo "register {$c['email']} => $code\n";
    if ($code >= 400) {
        echo substr($raw, 0, 300)."\n";
        // try login if already exists
        [$lc, $ld] = req('POST', $base.'/auth/login', [
            'email' => $c['email'],
            'password' => $c['password'],
        ]);
        echo "login_fallback=$lc\n";
        if ($lc === 200) {
            $created[] = [
                'email' => $c['email'],
                'password' => $c['password'],
                'token' => $ld['token'] ?? null,
                'user_id' => $ld['user']['id'] ?? null,
                'name' => $c['name'],
            ];
        }
        continue;
    }
    $created[] = [
        'email' => $c['email'],
        'password' => $c['password'],
        'token' => $data['token'] ?? null,
        'user_id' => $data['user']['id'] ?? null,
        'name' => $c['name'],
        'profile_hint' => $data,
    ];
}

file_put_contents(__DIR__.'/betterhelp_counselors.json', json_encode($created, JSON_PRETTY_PRINT));
echo "wrote betterhelp_counselors.json count=".count($created)."\n";
