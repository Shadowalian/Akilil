# Akilil local Jitsi

Self-hosted **docker-jitsi-meet** (`stable-11146-2`) for private Akilil sessions.

## Ports

| Service | URL / port |
|---------|------------|
| Meet UI | http://127.0.0.1:18080 |
| Laravel API | http://127.0.0.1:8000 |
| JVB Colibri | 127.0.0.1:8089 |

## Start / stop

```bash
cd jitsi
docker compose up -d
docker compose down
docker compose logs -f web
```

## Laravel

`friend-backend/.env` must match JWT secrets in `jitsi/.env`:

- `JITSI_BASE_URL=http://127.0.0.1:18080`
- `JITSI_USE_JWT=true`
- `JITSI_JWT_APP_ID=akilil`
- `JITSI_JWT_SECRET=<same as JWT_APP_SECRET>`

See `akilil-secrets.env` (gitignored) for the generated values.

## Room modes (sessions, groups, live)

Laravel builds every room URL from `config/jitsi.php` → `modes`:

| Mode | Used for | Behaviour |
|------|----------|-----------|
| `consult` | 1:1, couples, family | everyone on camera |
| `group` | group therapy, cooking classes | tile view, members join muted |
| `broadcast_host` | the person going live | full controls |
| `broadcast_view` | live audience | receive-only: no mic/camera buttons, no device prompt |

Comments, likes and gifts are **not** Jitsi features: the apps draw them over
the video and talk to the Laravel API (`/api/live-streams/*`).

### Production checklist for live

- `ENABLE_AUTH=1`, `AUTH_TYPE=jwt` and `JITSI_USE_JWT=true` in Laravel, so only
  tokens minted by the API can enter a room.
- `ENABLE_AV_MODERATION=1` (default). The host app switches moderation on when
  it joins, so viewers cannot unmute.
- Viewer lock-down is otherwise client configuration. For large audiences and
  hard server-side receive-only, enable Jitsi visitors (`ENABLE_VISITORS=1`
  plus the `VISITORS_*` settings in `docker-compose.yml`) and add JVBs.
- Serve Meet on a real hostname with a valid certificate and build the apps
  with `--dart-define=AKILIL_MEET_HOST=meet.example.com`.
