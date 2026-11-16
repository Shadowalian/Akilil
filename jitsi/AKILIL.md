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
