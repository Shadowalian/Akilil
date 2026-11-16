#!/bin/sh
set -e
cd /var/www/html

mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
chmod -R ug+rwx storage bootstrap/cache || true

if [ -f /run/secrets/notused ]; then true; fi

# Install PHP deps if missing (first boot after upload without vendor)
if [ ! -f vendor/autoload.php ]; then
  echo "Running composer install..."
  composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
fi

if [ -n "$DB_HOST" ]; then
  echo "Waiting for database..."
  i=0
  while [ $i -lt 60 ]; do
    if php -r "try { new PDO('mysql:host='.getenv('DB_HOST').';port='.(getenv('DB_PORT')?:3306).';dbname='.getenv('DB_DATABASE'), getenv('DB_USERNAME'), getenv('DB_PASSWORD')); exit(0);} catch (Throwable \$e) { exit(1);}"; then
      echo "Database is up"
      break
    fi
    i=$((i+1))
    sleep 2
  done
fi

php artisan config:clear || true
php artisan migrate --force
php artisan db:seed --force || true
php artisan storage:link || true
php artisan filament:assets || true

# Ensure demo client + professional exist (shared credentials for QA)
php -r "
require 'vendor/autoload.php';
\$app = require 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

\$client = App\Models\User::updateOrCreate(
  ['email' => 'demo@akilil.app'],
  ['name' => 'Demo User', 'password' => Illuminate\Support\Facades\Hash::make('CandyPass1'), 'role' => 'user', 'email_verified_at' => now()]
);
App\Models\Wallet::firstOrCreate(['user_id' => \$client->id], ['currency' => 'USD', 'balance_cents' => 5000]);
echo \"demo user {\$client->id}\n\";

\$pro = App\Models\User::updateOrCreate(
  ['email' => 'pro@akilil.app'],
  ['name' => 'Demo Pro', 'password' => Illuminate\Support\Facades\Hash::make('CandyPass1'), 'role' => 'professional', 'email_verified_at' => now()]
);
App\Models\Wallet::firstOrCreate(['user_id' => \$pro->id], ['currency' => 'USD', 'balance_cents' => 0]);
\$catId = App\Models\Category::where('is_active', true)->orderBy('sort_order')->value('id');
\$profile = \$pro->professionalProfile()->updateOrCreate(
  ['user_id' => \$pro->id],
  [
    'category_id' => \$catId,
    'bio' => 'Seeded demo professional for Akilil.',
    'verification_status' => 'approved',
    'badge_active' => true,
    'badge_issued_at' => now(),
    'hourly_rate_cents' => 5000,
    'currency' => 'USD',
    'session_duration_minutes' => 45,
    'is_accepting_clients' => true,
  ]
);
\$hasUpcoming = App\Models\Appointment::where('professional_user_id', \$pro->id)
  ->where('scheduled_at', '>=', now()->subHour())
  ->whereIn('status', ['pending', 'confirmed'])
  ->exists();
if (!\$hasUpcoming) {
  App\Models\Appointment::create([
    'user_id' => \$client->id,
    'professional_user_id' => \$pro->id,
    'professional_profile_id' => \$profile->id,
    'scheduled_at' => now()->addMinutes(10),
    'user_timezone' => 'UTC',
    'professional_timezone' => 'UTC',
    'duration_minutes' => 45,
    'session_type' => 'video',
    'status' => 'confirmed',
    'price_cents' => 5000,
    'currency' => 'USD',
    'confirmed_at' => now(),
  ]);
}
echo \"demo pro {\$pro->id} profile {\$profile->id}\n\";
" || true

exec docker-php-entrypoint "$@"
