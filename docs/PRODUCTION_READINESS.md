# Akilil production readiness

Status: **not ready for public launch yet.** The apps and API are feature-complete for a closed beta. The blockers below must be cleared before real users and real money.

## Fixed in this audit
- **Payments fail closed.** In production without Stripe keys the API returns 503 "Payments are not set up yet". It no longer falls back to the fake gateway. The fake confirm endpoint is a 404 outside local and testing.
- **Demo mode** can no longer be switched on in production.
- **Login throttling:** 5 attempts a minute per email and IP, on top of a 60 a minute IP ceiling.
- **API tokens expire** after `SANCTUM_TOKEN_LIFETIME_MINUTES` (default 30 days). Expired tokens are pruned daily.
- **HTTPS:** HTTPS is forced for generated URLs in production. Proxy headers are trusted (`TRUSTED_PROXIES`).
- **Dependencies:** upgraded to Laravel 12. `composer audit` now reports 0 advisories, down from about 40, including a critical token-auth bypass.
- **Journal and mood saves:** these never worked before (field-name mismatch). They are fixed and covered by contract tests.
- Backend: 181 tests pass.

## Blockers before launch
1. **Payment gateway.** Only Stripe is wired, and it needs real keys. Ethiopian users need Chapa or Telebirr.
2. **Deploy script.** `deploy/entrypoint.sh` creates `demo@akilil.app` and `pro@akilil.app` with a known password on every boot. Remove this before production, along with `db:seed` against production.
3. **Scheduler.** `deploy/docker-compose.yml` has a queue worker but no `schedule:work` service. Without it, vent purging and token pruning never run.
4. **TLS and domain.** nginx listens on port 80 only. Add a certificate (or a TLS proxy) and set `APP_URL` to https.
5. **Production `.env`:**
   - `APP_ENV=production` and `APP_DEBUG=false`.
   - A real mail driver (currently `log`).
   - `JITSI_ALLOWED_IFRAME_ORIGINS` set to your domains, not `*`.
6. **Push notifications.** The FCM/APNs keys are empty, so reminders arrive only in the app and by email.
7. **Jitsi.** It needs a server with a valid certificate and JWT auth configured.
8. **Mobile release.** Check these on real devices:
   - Bundle IDs and signing keys.
   - Android cleartext traffic off.
   - iOS camera and microphone usage strings.
   - The API base URL compiled with `--dart-define=FRIEND_API_BASE_URL=https://…`.
9. **Human review:**
   - A native speaker reviews the Amharic.
   - A clinician reviews the crisis flows and safety plan.
   - Legal review of the privacy policy and terms, and of data handling for minors' accounts.
10. **Backups.** Set up a database backup schedule and test a restore.
