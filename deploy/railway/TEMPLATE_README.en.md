# Deploy & Host Grape

> An AI-native DevOps platform: agent-driven task orchestration, skill library and repository hosting in one place.

## Deploy and Host Grape

Grape turns your development workflow (issues, tasks, reviews, releases) into tasks that agents can execute, and unifies skills, project templates and repository hosting behind a single WebUI.

### About Hosting Grape

This template builds **a single service** from `Dockerfile.railway` at the repository root, listening on port **3000** with automatic HTTPS.

- **Persistent storage**: a volume is mounted at `/app/data` (SQLite session store, skill storage, engine home directory and logs) so nothing is lost on redeploy.
- **Ready-to-use defaults**: you only provide `LLM_API_KEY`. `JWT_SECRET` is generated with template variable functions, and the public base URL is derived from the platform domain when the container starts.
- **Browser-only bootstrap**: no CLI required. Open the domain, register with username + password (email verification is skipped when no mail service is configured), and you are in.

### Common Use Cases

- Automate issue/PR flow into agent tasks
- Standardize team engineering practice with a shared skill library
- Attach the same pipeline and review rules to multiple repositories
- Serve as the single entry point for internal AI development assistance

### Dependencies for Grape Hosting

- A model API key (`LLM_API_KEY`) for an OpenAI-compatible endpoint — a vendor (OpenAI / Anthropic / DeepSeek…) or your own gateway such as `https://<your-gateway>/v1`.
- A persistent volume provisioned automatically by the platform (mounted at `/app/data`).

### After deployment

1. Open the domain and register with username + password
2. Sign in to `/admin` with `GRAPE_ADMIN_PASSWORD` (visible in the Variables tab) and change it
3. In Agent Settings, confirm the execution engine is online (this template ships `opencode`) and pick a model

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| UI works but tasks say "no available engine" | `LLM_API_KEY` not set | Add `LLM_API_KEY` (optionally `LLM_BASE_URL` / `LLM_MODEL`) in Variables; the service redeploys automatically |
| Task fails with auth error or 404 | Key does not match the endpoint | Check `LLM_BASE_URL` ends with `/v1`, and that `LLM_MODEL` is prefixed with `LLM_PROVIDER_ID` (default `custom`) |
| `server_base_url` points at `localhost:3000` | The domain was created after the container started | Click `Redeploy` once, or set `SERVER_BASE_URL=https://<your-domain>` explicitly |
| OAuth login callback fails | Redirect URI not registered | Register `https://<your-domain>/api/auth/callback/{gitcode,github}` in the OAuth app |
| Login state or data disappears after restart | Volume missing or wrong mount path | Ensure the volume is mounted at `/app/data` |

### Container settings (applied automatically)

| Item | Value |
|---|---|
| Build | `Dockerfile.railway` at repo root (specified by `railway.json`) |
| Port | `3000` |
| Volume | `/app/data` |
| Health check | `/api/health` (300 s timeout; first boot pulls the template library) |
| Region | Not pinned — uses the deployer account's default region |

### References

- Project documentation: see `README.md`
- Production deployment: `docs/DEPLOYMENT.zh.md` / `docs/CONFIGURATION.zh.md`
