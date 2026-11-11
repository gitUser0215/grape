![](https://raw.githubusercontent.com/gitUser0215/grape/main/deploy/railway/icon.png)

# Deploy Grape

An AI-native DevOps platform: agent-driven pipelines, a shared skill library and repository hosting

## Deploy and Host Grape

Grape turns your development workflow (issues, tasks, reviews, releases) into tasks that agents can execute, and unifies skills, project templates and repository hosting behind a single WebUI.

### About Hosting Grape

This template builds **a single service** from `Dockerfile.railway` at the repository root, listening on port **3000** with automatic HTTPS.

- **Persistent storage**: a volume is mounted at `/app/data` (SQLite session store, skill storage, engine home directory and logs) so nothing is lost on redeploy.
- **Ready-to-use defaults**: you only provide `LLM_API_KEY` (optionally `LLM_PROVIDER` to pick a vendor). `JWT_SECRET` is generated with template variable functions, the public base URL is derived from the platform domain at container start, and **the model list is discovered from your endpoint automatically** — no model name required.
- **Browser-only bootstrap**: no CLI required. Open the domain, register with username + password (email verification is skipped when no mail service is configured), and you are in.

### Common Use Cases

- Automate issue/PR flow into agent tasks
- Standardize team engineering practice with a shared skill library
- Attach the same pipeline and review rules to multiple repositories
- Serve as the single entry point for internal AI development assistance

### Dependencies for Grape Hosting

- A model API key (`LLM_API_KEY`) for an OpenAI-compatible endpoint — a vendor (`LLM_PROVIDER=openai|deepseek|openrouter`) or your own gateway (`LLM_BASE_URL`).
- **No engine install needed**: the image ships `opencode` (the only bundled engine; API-key based, works out of the box).
- A persistent volume provisioned automatically by the platform (mounted at `/app/data`).

### After deployment

1. Open the domain and register with username + password
2. Sign in to `/admin` with `GRAPE_ADMIN_PASSWORD` (visible in the Variables tab) and change it
3. In Agent Settings, confirm the execution engine is online (this template ships `opencode`) and pick a model — the list is discovered from your endpoint at startup

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| UI works but tasks say "no available engine" | `LLM_API_KEY` not set | Add `LLM_API_KEY` (optionally `LLM_BASE_URL` / `LLM_MODEL`) in Variables; the service redeploys automatically |
| Task fails with auth error or 404 | Key does not match the endpoint | Check `LLM_BASE_URL` ends with `/v1`; when using a preset, check the spelling of `LLM_PROVIDER` |
| Model list is empty, or `Failed to initialize provider` | Engine config not generated (missing key) or endpoint unreachable | Check container logs for `[entrypoint] engine config ->` with `models=` > 0; set `LLM_API_KEY` first |
| `server_base_url` points at `localhost:3000` | The domain was created after the container started | Click `Redeploy` once, or set `SERVER_BASE_URL=https://<your-domain>` explicitly |
| OAuth login callback fails | Redirect URI not registered | Register `https://<your-domain>/api/auth/callback/{gitcode,github}` in the OAuth app |
| Login state or data disappears after restart | Volume missing or wrong mount path | Ensure the volume is mounted at `/app/data` |

### How to configure the model endpoint (pick one)

| Your case | Variables to set |
|---|---|
| OpenAI API key | `LLM_API_KEY` + `LLM_PROVIDER=openai` |
| DeepSeek / OpenRouter | `LLM_API_KEY` + `LLM_PROVIDER=deepseek` (or `openrouter`) |
| Your own gateway | `LLM_API_KEY` + `LLM_BASE_URL=https://<your-gateway>/v1` |

Add `LLM_MODEL=<model-id>` only if you want to pin a default model (`custom/<model-id>` also works).
**Leaving `LLM_MODEL` empty is the recommended setup**: at container start, every model returned by your endpoint's `/v1/models` is registered, so you can switch models in Agent Settings after deployment.

### Engines: exactly one is bundled

The image ships a single engine, `opencode` (`npm i -g opencode-ai`) — the only engine that runs with nothing but an API key, which is what a public template needs.

To use AIShell / Codex / dsh / CodeArts: install that CLI **on your own machine** and register it as a **remote worker** with a Grape `rta_` token; tasks are routed there. Nothing extra is needed inside the container.

### Upgrade policy (no auto-upgrade)

This template **does not upgrade itself**. Code updates only take effect when you confirm them:

1. When the template author merges an update, your Railway project shows an "update available" notice;
2. Before applying, read the [CHANGELOG](https://github.com/gitUser0215/grape/blob/main/deploy/railway/TEMPLATE_CHANGELOG.md) to see what changed and whether manual steps are needed;
3. Apply from the notice when you are ready. Otherwise you stay on your current version with no impact.

Notes:

- `Settings → Source → Auto deploy` is **Disabled** by default for template-deployed services; keep it disabled to stay fully manual.
- Data lives on the volume mounted at `/app/data`, so upgrades keep your data, but there is a short downtime window (tens of seconds).
- Rollback is available from the Deployments history (retention is limited).
- To modify the source yourself, use **Eject** under `Settings → Source`.

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
