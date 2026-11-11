# Hosted-platform deployment materials (`deploy/hosted`)

Everything needed to publish Grape on a container hosting platform lives here. Neither the directory
nor the filenames reference any vendor, so the same set works for any platform that can build from a
Dockerfile, inject a domain variable and attach a persistent volume.

| File | Purpose |
|---|---|
| `Dockerfile` | Image definition for the platform build: Python runtime + execution engine (`opencode`) + project templates baked in |
| `entrypoint.sh` | Idempotent container bootstrap: session secret, public base URL, template pre-sync, engine model config |
| `listing.md` | Marketplace listing copy (English) — overview, model endpoint guide, engine notes, upgrade policy |
| `variables.md` | Variable table: which are required, which are hidden defaults, which the platform injects |
| `icon.png` | Marketplace icon |

There is no changelog file here on purpose: the platform notifies deployers on every merge to the
default branch, and the commit history is the changelog —
<https://github.com/gitUser0215/grape/commits/main>.

## The platform still needs one config file

`railway.json` at the repository root is a **filename required by the platform** (config-as-code,
read only from the repo root). It does one thing: point the build at `deploy/hosted/Dockerfile`.
When moving to another platform, delete it and write that platform's equivalent — nothing in this
directory has to change.

## Public base URL resolution order

1. `SERVER_BASE_URL` (explicit, highest priority)
2. `PUBLIC_DOMAIN` (generic; any platform can inject it)
3. `RAILWAY_PUBLIC_DOMAIN` (injected by this platform)

If none is set the container only logs a warning and keeps starting (the app works, but OAuth
callbacks would point at localhost).

## Self-hosting

Unrelated to hosted platforms: use the repository's root `Dockerfile` / `docker-compose.yml`.
See `docs/DEPLOYMENT.zh.md`.
