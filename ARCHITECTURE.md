# Akilil Platform — Architecture

> **Task 0 deliverable.** This document captures every architectural
> decision made during initial scaffolding. Later tasks may revisit
> individual sections — schema (Task 1), admin modules (Task 6), payment
> integrations (Task 9) — but the structural choices below are locked in
> unless an explicit issue forces a change.

---

## 1. Repo layout (monorepo, three top-level folders)

```
C:\Users\user\Desktop\fd\
├── ARCHITECTURE.md            ← you are here
├── friend-backend\            Laravel 11 — API + admin panel (Filament)
└── friend-flutter\            Flutter monorepo (Melos)
    ├── melos.yaml
    ├── pubspec.yaml           workspace root
    ├── analysis_options.yaml  shared lint config
    ├── apps\
    │   ├── user_app\          end-user app
    │   └── professional_app\  pro-side app
    └── packages\
        └── core\              shared theming, networking, Jitsi, Reverb
```

**Why a monorepo, not three repos:** simpler version management across
the Flutter apps (they share `core/`), one CI pipeline, one git clone.
The Laravel side and the Flutter side are kept as separate top-level
folders so they can be split into independent repos later if needed
(e.g. if you ever want to host the marketing site in its own repo).

---

## 2. Backend (friend-backend)

| Concern | Choice | Notes |
|--------|--------|-------|
| Framework | **Laravel 11** on **PHP 8.2.12** | Prompt asked for 8.3+ but XAMPP ships 8.2.12 — fine for Laravel 11. Upgrade PHP when convenient; Task 11 deployment will require PHP 8.3. |
| Admin panel | **Filament 3.3** | Ships auth, CRUD, charts, role hooks. Beats hand-rolled Livewire for our scope. |
| API auth | **Sanctum 4.3** (Bearer tokens for Flutter) | Domain-state list in `SANCTUM_STATEFUL_DOMAINS` for any future web admin SPA. |
| RBAC | **spatie/laravel-permission 6.10** | `admin`, `support`, `moderator` roles; granular abilities added in Task 6. |
| Realtime | **Laravel Reverb 1.10** | WebSocket server (`php artisan reverb:start`); private channels for chat/notifications. |
| Queue driver | **database** (dev) → **Redis** (prod, Task 11) | Horizon is Linux-only (uses `ext-pcntl`); skipped on this Windows box. Production runbook in `docs/deploy.md` (Task 11). |
| Object storage | **local** (dev) → **S3-compatible** (prod) | Professional credential documents must NEVER be on a `public` disk. `PRIVATE_DISK` env wires the right disk. |
| Database | **MySQL 8 via XAMPP** (running on `127.0.0.1:3306`) | Database `friend` created at scaffold time. |

### Filament panel
URL: **`/admin`** — registered by `App\Providers\Filament\AdminPanelProvider.php`.
Color palette is wired from the **design tokens** (`#2E6B4E` primary green,
`#E8823A` accent orange) so every Filament component is on-brand from day one.
The full design-system styling lives in the web token CSS (Task 0.5).

**Default admin user** (from `RolesAndAdminSeeder`):
- email: `admin@akilil.app`
- password: from `BOOTSTRAP_ADMIN_PASSWORD` env, default `changeme-9k2x`

### Reverb
Configured via `REVERB_*` env keys (see `.env.example` §6). The mobile
apps connect over `pusher_channels_flutter` (Reverb speaks the Pusher
protocol). Default local: `ws://10.0.2.2:8080` (Android emulator → host).

---

## 3. Flutter monorepo (friend-flutter)

### Workspace organization
- **Melos** is wired at the root but each app also references `core`
  directly via a `path:` dependency, so `melos bootstrap` is **optional**
  for everyday dev. We use Melos for cross-package scripts
  (`melos run lint:all`, `melos run build:user:android`, etc.).
- **State management: Riverpod 2.5** with `riverpod_generator` for code-gen
  providers. Rationale: 1/3 the boilerplate of Bloc for most screens,
  easier testing via `ProviderContainer`, and `flutter_riverpod` is the
  default choice for production Flutter in 2026.

### packages/core
Lives at `packages/core/lib/`:
- `theme/design_tokens.dart` — palette, type scale, radii, elevation
- `theme/app_theme.dart` — `FriendAppTheme.light()` / `.dark()` built against the tokens
- `networking/api_client.dart` — Dio + Sanctum Bearer interceptor
- `auth/token_storage.dart` — `flutter_secure_storage`-backed token store
- `jitsi/jitsi_session_view.dart` — InAppWebView wrapper for the Jitsi room
- `realtime/reverb_client.dart` — Pusher-protocol client wired to Reverb

Apps import via `package:core/core.dart` — single barrel export keeps
the public surface intentional.

### apps/user_app — feature skeleton (filled in Task 7)
```
lib/
├── main.dart
├── app.dart                    ← root MaterialApp, theme switch, router
└── features/
    ├── auth/
    ├── discovery/
    ├── booking/
    ├── session_room/
    ├── journal/
    ├── goals_habits/
    ├── vents/
    ├── community/
    ├── messaging/
    ├── notifications/
    ├── payments/
    └── settings/
```

### apps/professional_app — feature skeleton (filled in Task 8)
```
lib/
├── main.dart
├── app.dart
└── features/
    ├── onboarding/
    ├── availability/
    ├── session_host/
    ├── clients/
    ├── post_session/
    ├── earnings/
    ├── group_sessions/
    ├── analytics/
    ├── community/
    └── notifications/
```

---

## 4. WebRTC — Jitsi (chosen for free + open-source)

### Decision
**Jitsi** via `meet.jit.si` for dev, self-hosted Docker Compose for prod.

### Implementation
- **Backend:** `App\Services\JitsiService` (in `friend-backend`) issues
  `{room_url, token, jwt_required}` when a session starts. Config lives
  in `config/jitsi.php`. JWT signing is wired via `firebase/php-jwt`
  for self-hosted production; dev default is anonymous (matches
  `meet.jit.si`).
- **Flutter:** `JitsiSessionView` (in `core`) renders the room via
  `flutter_inappwebview`. We **deliberately do not use the
  `jitsi_meet` community plugin** — it's flaky on newer Flutter
  versions and forces its own UI chrome (which would fight our
  Design System). Wrapping the web UI lets both apps brand the
  surrounding chrome (top bar, leave button, end-call badge).

### Privacy note (for prod)
`meet.jit.si` is a **shared public server** with no SLA. For real
production traffic we **must** self-host Jitsi (Task 11 deploys the
Docker stack with prosody + jicofo + jvb + nginx + JWT auth). Switching
is a single env change: `JITSI_DOMAIN`, `JITSI_USE_JWT=true`,
`JITSI_JWT_APP_ID`, `JITSI_JWT_SECRET`.

---

## 5. Database

- MySQL 8 via XAMPP on `127.0.0.1:3306`
- Database: `friend` (utf8mb4 / unicode_ci)
- Dev user: `root` (empty password — XAMPP default). **Lock this down
  before Task 8 (payments) or Task 10 (security audit).**
- All migrations live in `friend-backend/database/migrations/`. Task 1
  adds the real schema (users, professionals, appointments, sessions,
  journal, mood, goals, habits, vents, community, conversations,
  messages, wallets, transactions, subscriptions, payouts, ratings,
  notifications, audit_logs, crisis_flags).

---

## 6. Roles & permissions

Single `users` table with a `role` column (added in Task 1) selects
the persona:

| `users.role` | Description | Spatie role |
|--------------|-------------|-------------|
| `user` | default end-user | — |
| `professional` | user with a `professional_profiles` row (1:1) | — |
| `admin` | platform admin | `admin` |
| `support` | support staff | `support` |
| `moderator` | community/content moderator | `moderator` |

The two-tier approach is intentional:
- `users.role` = persona (UI routing, billing, onboarding flow)
- Spatie roles = admin-panel abilities

**Why not all-Spatie?** Persona routing ("show me onboarding or the
professional dashboard") happens before login in many cases; we want
a simple column to query. Admin-side RBAC needs Spatie's permission
graph (multiple abilities, role inheritance).

---

## 7. Configuration

`.env.example` covers every key we'll need across all 12 tasks:
- App / DB / Cache / Queue / Session / Mail
- Reverb (broadcasting)
- Sanctum (API auth)
- Jitsi (domain, JWT, room prefix)
- FCM / APNs (push notifications)
- Stripe / Apple Pay / Google Pay / Chapa / Telebirr (payments)
- Crisis detection (provider, threshold, alert emails)

Tasks 2, 4, 8, 9, 10 add the real values; defaults are local-only
placeholders so nothing leaks into a prod `.env`.

---

## 8. Open decisions (to revisit in later tasks)

| # | Decision | Decided in | Why deferred |
|---|----------|------------|--------------|
| 1 | Crisis-detection provider (Perspective API vs OpenAI moderation vs custom) | Task 5 | v1 is a heuristic; we choose the real one once we see the false-positive rate on real journal/vent examples. |
| 2 | Self-hosted Jitsi vs JaaS (8x8's paid Jitsi) | Task 11 deploy | We need prod volume data first. Default: self-host. |
| 3 | Push provider for Flutter (FCM unified vs FCM+APNs split) | Task 4 | Departs from "use one provider" until we measure the abstraction overhead. |
| 4 | Object storage vendor (AWS S3 vs Cloudflare R2 vs Backblaze B2) | Task 11 | Cost depends on egress volume; pick once we know it. |
| 5 | `flutter_inappwebview` license | Task 8 | BSD-3-Clause per pub.dev — already permissive; just confirm before public app release. |

---

## 9. Setup commands (what was actually run)

### Backend
```bash
cd C:\Users\user\Desktop\fd\friend-backend
composer create-project laravel/laravel . "11.*"
composer require laravel/sanctum laravel/reverb
composer require "filament/filament:3.*" "spatie/laravel-permission:^6.10"
composer require firebase/php-jwt:"^6.10"
php artisan install:api
php artisan reverb:install
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
# Create MySQL database 'Akilil' via XAMPP shell
php artisan migrate:fresh --seed
```

### Flutter
```bash
cd C:\Users\user\Desktop\fd\friend-flutter
flutter create --org=app.friend --project-name=friend_user          --template=app apps/user_app
flutter create --org=app.friend --project-name=friend_professional  --template=app apps/professional_app
flutter create --template=package packages/core
# (deps already written to pubspec.yaml; resolve per package)
cd packages/core && flutter pub get && cd ../..
cd apps/user_app && flutter pub get && cd ../..
cd apps/professional_app && flutter pub get && cd ../..
# Optional: dart pub global activate melos && melos bootstrap
```

---

## 10. Verification (what was confirmed working)

- `php artisan migrate:fresh --seed` runs all 5 migrations + seeds the
  default admin (`admin@akilil.app`) and Spatie roles
- `php artisan route:list` confirms `/admin`, `/admin/login`,
  `/admin/logout`, `/broadcasting/auth` are all wired
- `flutter pub get` resolves cleanly in `packages/core`, `apps/user_app`,
  `apps/professional_app`

What is **not yet wired** (intentional — comes in later tasks):
- Payment gateways (Task 8 — Chapa, Telebirr, Stripe, Apple Pay, Google Pay)
- Flutter app screens (Tasks 7 & 9)
- Production hardening: rate limiting, CSP, secrets manager, image moderation (Task 10)
- Jitsi Docker compose for self-hosted (Task 11)

---

## 11. Task 6 — Admin Dashboard (delivered)

**Stack:** Filament 3.3, spatie/laravel-permission, custom AuditLogObserver.

**Modules shipped:**

| Resource           | Purpose                                          | Key actions                                    |
| ------------------ | ------------------------------------------------ | ---------------------------------------------- |
| Dashboard          | Stats overview + charts                          | (read-only widgets)                            |
| UserResource       | Manage end-users + professionals                 | Suspend / reactivate / 2FA status / role       |
| ProfessionalProfile| Verification queue (default filter = pending)    | Approve / reject / toggle badge                |
| CrisisFlagResource | High-visibility crisis queue                     | Mark handled / false positive / assign         |
| TransactionResource| All financial transactions                       | Date + gateway + status filters; refund stub   |
| PayoutResource     | Pro payouts to bank                              | Approve / mark sent                            |
| CommunityPostResource | Moderation                                     | Remove / clear flags                           |
| CommunityReportResource | Report queue                                 | Uphold / dismiss (auto-removes post on uphold) |
| CallSessionResource| Session monitoring (metadata only)                | (read-only)                                    |
| AuditLogResource   | Read-only audit trail                            | (read-only)                                    |

**2FA gating:** `PanelEnsureTwoFactorEnabled` middleware redirects any
admin/support/moderator user without confirmed TOTP to `/admin/2fa-setup`.
API-side `EnsureTwoFactorEnabled` returns 423 JSON. Implementation
(TOTP + Base32) is from scratch — no `otphp` library, due to
packagist's `p2/` endpoint returning 404 during build.

**Audit log:** `AuditLogObserver` registered on 11 models via
`AdminModuleServiceProvider` (added to `bootstrap/providers.php`
BEFORE the Filament panel provider). Every admin write produces a row.
Before/after snapshots store only the diff; encrypted columns' plaintext
is never logged.

**Dashboard widgets:** `StatsOverview` (5 cards: users, pros, sessions,
crisis flags, revenue) + `SessionsChart` (last 14 days, bookings vs
revenue) + `RevenueChart` (12-month rolling).

**Tests:** 10 new feature tests in `AdminFlowTest.php`. Cumulative
`php artisan test`: **81 passed, 242 assertions**.

**Deviations from spec:**
- Crisis detection v1 (Task 5) is documented as harm-reduction, not
  diagnostic. Admin Reviewer step is the deciding one — no auto-messages
  or auto-emergency calls in v1.
- Audit log is the only writer to `audit_logs`; the observer replaces
  the spec's "every admin controller calls AuditLog::create" pattern.
- Filament's default `Authenticate` middleware was extended (not
  replaced) so the 2FA gate runs in the same chain.

---

## 12. Task 7 — User Flutter App (delivered)

**Stack:** Flutter 3.41.9, Riverpod 2.5.1, go_router 14.6, dio 5.7,
fl_chart 0.69, flutter_inappwebview 6.1 (Jitsi wrapper), qr_flutter
4.1, intl 0.20, cached_network_image 3.4. Tests: flutter_test.

**Modules shipped (21 dart files):**

| Feature       | Files                                            | Notes                                          |
| ------------- | ------------------------------------------------ | ---------------------------------------------- |
| Bootstrap     | `main.dart`, `app.dart`, `router.dart`           | Riverpod-driven go_router; auth-gated redirect |
| Brand         | `features/brand/brand_assets.dart`               | Asset-free logo (design tokens only)           |
| Auth          | `auth_controller.dart`, `login/register/2fa_setup` screens | Token persistence; `/me` bootstrap            |
| Discovery     | `discovery_screen.dart`, `professional_detail_screen.dart` | Filters (category, language, price, badge)    |
| Booking       | `booking_screen.dart`, `appointments_screen.dart` | 14-day date strip, slot grid, cancel w/ refund |
| Session Room  | `session_room_screen.dart`                       | Jitsi JWT + WebView, branded chrome            |
| Messaging     | `conversations_screen.dart`, `conversation_screen.dart` | Polling v1; client_uuid offline idempotency    |
| Journal       | `journal_list/editor`, `mood_log/analytics`      | 1–7 mood scale, fl_chart line, encrypted note  |
| Profile       | `profile_screen.dart`                            | 2FA setup entry, logout                        |
| Shell         | `main_shell.dart`                                | 4-tab bottom nav (Sessions / Discover / Journal / Profile) |

**Architecture choices:**

- `AuthController` is a `ChangeNotifier` (not Riverpod-only) so go_router's
  `refreshListenable` can react to login/logout. Owns token storage
  via `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences
  on Android).
- All API access goes through the shared `dioProvider` (Bearer token
  interceptor). Auth bootstrap fires `/me` on app start; 401 → clear
  token → land on /login.
- Routes are namespaced in `AppRoutes`. The shell is a `ShellRoute`
  with bottom `NavigationBar`; 2FA setup is its own top-level route
  (not under the shell) so it can render during the auth-redirect.
- Jitsi runs in `flutter_inappwebview` with a custom branded AppBar
  (end-call, recording indicator). JWT is appended via the URL fragment.
- Mood analytics uses `fl_chart` `LineChart` with the spec palette
  (primary green line, accent orange dot).

**Tests:** 2 widget tests passing — brand mark renders, design tokens
match the spec. `flutter analyze` returns 0 errors (24 info-level lint
hints, mostly `unnecessary_underscores` from the standard `(_, __)`
pattern).

**Deferred to Task 8 / 9:**
- Reverb real-time wiring (conversations still poll every 5s as v1)
- Voice messages (record + audio playback UI)
- Community channels + posts (UI is empty; backend API exists)
- Vents (anonymous posting + ephemeral purge)
- Goals + habits UI (backend CRUD exists)
- Push notification permission flow
- Image picker for avatars
- Onboarding tour for new users

**Deviations from spec:**
- `google_fonts` is still the dev fallback for Fraunces / Inter. Task 12
  ships self-hosted font files in the marketing site bundle; the apps
  will pick them up via `assets:` in pubspec then. Today the dev build
  is fully on-brand; production builds need to ship the fonts in
  `assets/fonts/`.
- No freezed/json_serializable in the user app — used plain Dart
  classes with `fromJson`/`toJson`. Code-gen is overkill for the v1
  data shapes; revisit when the model count grows.

---

## 13. Task 8 — Pro App + Payments (delivered)

### Pro app

Same Melos monorepo, same Riverpod + dio stack, same design tokens.
Five-tab bottom nav: Today / Sessions / Schedule / Clients / Profile.

| Feature       | Files                                                       | Notes                                       |
| ------------- | ----------------------------------------------------------- | ------------------------------------------- |
| Bootstrap     | `main.dart`, `app.dart`, `router.dart`                      | Auth-gated, 2FA-aware redirect              |
| Auth          | `auth_controller.dart`, `login/register_pro/2fa_setup`      | `register-professional` flow + 2FA QR      |
| Brand         | `brand_stub.dart`                                           | Pro variant: 42% accent dot (host feel)    |
| Dashboard     | `dashboard_screen.dart`                                     | Today's sessions, 7-day earnings, nudge     |
| Sessions      | `sessions_screen.dart`, `session_host_screen.dart`          | List + Jitsi host room (branded AppBar)     |
| Availability  | `availability_screen.dart`                                  | Weekly rules + time-off blocks (FAB-driven) |
| Clients       | `clients_screen.dart`                                       | Session count + last-session date           |
| Earnings      | `earnings_screen.dart`                                      | 12-week line, payout history, request       |
| Onboarding    | `onboarding_screen.dart`                                    | 4-step wizard (profile, category, rate)     |
| Profile       | `profile_screen.dart`                                       | Edit, 2FA, payout method, logout            |
| Shell         | `main_shell.dart`                                           | 5-tab NavigationBar                         |

**Tests:** 2 widget tests passing (brand mark renders, design tokens
match the spec). `flutter analyze` 0 errors.

### Payments (backend)

**Architecture:** gateway-agnostic contract (`App\Services\Payments\PaymentGateway`)
with two implementations:

- **`StripeGateway`** — talks to the Stripe REST API directly via
  Laravel's HTTP client. Avoids the `stripe/stripe-php` composer
  package; the user can drop it in later by swapping the HTTP calls
  with `\Stripe\Checkout\Session::create(...)` (the caller code in
  WalletService / WebhookController does not change).
- **`FakeGateway`** — used in dev and tests. Returns a local URL
  pointing at `/api/wallet/topup/{reference}/confirm` so devs can
  simulate a webhook without Stripe CLI.

`PaymentsServiceProvider` chooses the gateway at boot:
- `FRIEND_PAYMENT_FAKE=1` → FakeGateway
- otherwise → StripeGateway (reads `STRIPE_SECRET` + `STRIPE_WEBHOOK_SECRET`)

**`WalletService`** owns the wallet lifecycle:
- `walletFor()` — lazy creation, currency-scoped
- `beginTopup()` — creates a pending `Transaction`, returns the
  gateway's `CheckoutSession`
- `completeTopup()` — webhook landing; idempotent (re-runs are no-ops);
  uses optimistic locking via the `version` column on `wallets`
- `debit()` — spends from wallet for a paid appointment; throws
  `DomainException` on insufficient balance
- `refund()` — creates a new `refund` transaction, calls the gateway,
  credits the wallet; rolls back on gateway failure

**Routes:**
- `POST /api/wallet/topup` — start a top-up, returns `{checkout_url, reference}`
- `POST /api/wallet/topup/{reference}/confirm` — dev-only, hidden in prod
- `POST /api/webhooks/stripe` — HMAC-verified, idempotent
- `GET  /api/me/wallet` — current balance + lifetime totals
- `GET  /api/me/wallet/transactions` — paginated ledger

**Tests:** 10 new tests in `PaymentFlowTest`:
- Wallet lazy-created on first read
- Top-up creates pending transaction, returns URL
- Fake-confirm endpoint completes top-up
- Webhook with valid HMAC signature completes top-up
- Webhook rejects bad signature (400)
- Top-up validates minimum amount
- Transactions list scoped to the authenticated user
- Complete-top-up is idempotent
- Debit fails on insufficient balance
- Debit succeeds with sufficient balance

**Cumulative test count:** `php artisan test` → **91 passed, 268 assertions**.

**Deviations from spec:**
- **Chapa / Telebirr / Apple Pay / Google Pay** are not implemented
  in v1. The `PaymentGateway` contract makes adding them
  one-file-each (Task 11 production hardening).
- **Stripe SDK swap deferred.** The user has a composer SSL cert
  issue (`curl error 60: unable to get local issuer certificate`)
  on this Windows box. The HTTP-based Stripe gateway works end-to-end
  in tests; the user can `composer require stripe/stripe-php` once
  the cert is fixed and replace the `Http::stripe(...)` calls in
  `StripeGateway` with `\Stripe\Checkout\Session::create(...)`.
- **No `Transaction` model factory** yet; tests use direct creates.
  Will add in Task 10 when factories get a polish pass.

**Open questions / known limitations:**
- The pro app's onboarding wizard uses 5 hardcoded category values;
  Task 12 should fetch the real categories from `/api/categories`.
- The earnings chart's data shape assumes the backend returns
  `{series: [{date, cents}]}` for the 12-week window. The endpoint
  stub at `/professional/earnings/summary` needs to be wired up
  in the next backend pass — currently the dashboard will 404.
- Stripe webhook secret in dev defaults to `test_webhook_secret`;
  production must set `STRIPE_WEBHOOK_SECRET` from the dashboard.