# Hosted-platform variable table

How to use: copy the **Description** column into the matching variable's Description field in the
template editor, so deployers see it in the deploy form.

Design rule: **exactly one required field** (`LLM_API_KEY`). Everything else is optional, generated
by a template variable function, or pre-set with a working default.

---

## 1. Visible variables (shown in the deploy form)

| Variable | Visibility | Value | Description (paste into the Description field) |
|---|---|---|---|
| `LLM_API_KEY` | **required** | empty — deployer fills | API key for an OpenAI-compatible model endpoint. Without a key the platform still deploys and you can sign in, but agent tasks cannot run. |
| `LLM_PROVIDER` | optional | **`openrouter`** (pre-selected) | Model endpoint preset. Options: `openrouter` (one key covers Claude / GPT / Gemini / Llama and more), `openai`, `gemini`, `groq`, `anthropic`, `deepseek`, `opengw`, or leave empty to use only `LLM_BASE_URL`. With a preset you can leave `LLM_BASE_URL` empty. |
| `LLM_BASE_URL` | optional | empty | Custom OpenAI-compatible endpoint, e.g. `https://<your-gateway>/v1`. Fill this to use a provider that has no preset (self-hosted vLLM, a corporate gateway, any OpenAI-compatible service). **Takes priority over `LLM_PROVIDER`** — when both are set, this address wins. |
| `LLM_MODEL` | optional | empty | Default model id, either `<model-id>` or `custom/<model-id>`. **Leave empty for most providers**: at startup Grape asks the endpoint for its model list and registers every model, so you can switch models later in Agent Settings. **Required for `anthropic`** (its OpenAI-compatible layer exposes no model list) — e.g. `claude-sonnet-4-5`. |
| `JWT_SECRET` | visible | `${{secret(64)}}` | Session signing key, generated automatically. Do not change it after the first deploy: every existing session is invalidated and all users are signed out. |
| `GRAPE_ADMIN_PASSWORD` | visible | `${{secret(24)}}` | Password for the `/admin` console (OAuth app credentials, provider config). It is stored as a plain variable and visible in the Variables tab — change it after the first sign-in. |
| `LLM_PROVIDER_ID` | optional (advanced) | `custom` | Identifier used inside the engine config file (`provider.<id>`). Change it only if you want a custom provider name; it must stay consistent with the model ids you reference. |

## 2. Model endpoint recipes (pick one row)

| Scenario | Variables to set | What happens |
|---|---|---|
| **OpenRouter — recommended for overseas users** | `LLM_API_KEY` only (provider is pre-set to `openrouter`) | Endpoint defaults to `https://openrouter.ai/api/v1`. Every model the key can access (~468 at the time of writing) is registered at startup. |
| OpenAI directly | `LLM_API_KEY` + `LLM_PROVIDER=openai` | Endpoint defaults to `https://api.openai.com/v1`. |
| Google Gemini | `LLM_API_KEY` + `LLM_PROVIDER=gemini` | Endpoint defaults to Google's OpenAI-compatible path (`/v1beta/openai`). |
| Groq | `LLM_API_KEY` + `LLM_PROVIDER=groq` | Endpoint defaults to `https://api.groq.com/openai/v1`. |
| Anthropic | `LLM_API_KEY` + `LLM_PROVIDER=anthropic` + `LLM_MODEL=claude-sonnet-4-5` | `LLM_MODEL` is mandatory here: the OpenAI-compatible layer has no `/models` list, and the entrypoint stops with an explicit error if no model id is given. |
| DeepSeek / OpenGW (China-hosted) | `LLM_API_KEY` + `LLM_PROVIDER=deepseek` or `opengw` | Endpoint defaults accordingly. Overseas users will usually prefer OpenRouter instead. |
| Self-hosted / corporate gateway | `LLM_API_KEY` + `LLM_BASE_URL=https://<your-gateway>/v1` (leave `LLM_PROVIDER` empty) | Endpoint is used as given; if it exposes `/models`, its model list is registered automatically. |

> **Which one wins?** `LLM_BASE_URL` > `LLM_PROVIDER` preset > nothing. If neither is set, the
> entrypoint warns and skips the engine config (the platform runs, but tasks report "no available
> engine").

## 3. Hidden variables (pre-set, not shown in the form)

| Variable | Value | Why |
|---|---|---|
| `COOKIE_SECURE` | `true` | The platform serves HTTPS only; production checks enforce it. Do **not** copy this into a plain-HTTP self-hosted deployment or sign-in breaks. |
| `GRAPE_PORT` | `3000` | Must match the container port, `EXPOSE 3000` in the Dockerfile and the template's public port. |
| `DEVOPS_DB_BACKEND` | `sqlite` | Default SQLite; the database file lives on the `/app/data` volume, so it survives redeploys. |
| `GRAPE_HOSTED_BOOTSTRAP` | unset (auto) | Hosted bootstrap switch: `1` = always run, `0` = never, unset = auto-detect from the variables below. The bootstrap fills in the JWT secret, the public base URL and the engine model config. On a hosted platform it always runs; without hosted signals it is inert and only `exec`s the original command. |

## 4. Injected by the platform — do not set by hand

| Variable | Source | Used by Grape |
|---|---|---|
| `RAILWAY_PUBLIC_DOMAIN` | injected once a domain exists (platform-specific names differ per host) | `entrypoint.sh` derives `server_base_url`, `webhook_url` and `TRUSTED_HOSTS` from it. Any platform that provides `PUBLIC_DOMAIN` or `SERVER_BASE_URL` works the same way. |
| `RAILWAY_ENVIRONMENT_NAME`, `RAILWAY_PROJECT_ID` | injected by the platform | Only used to detect "we are running on a hosted platform" when `GRAPE_HOSTED_BOOTSTRAP` is unset. |

## 5. Optional overrides (advanced troubleshooting)

| Variable | Default | Effect |
|---|---|---|
| `SERVER_BASE_URL` | empty | Explicit public base URL; highest priority, overrides any platform-injected domain. |
| `PUBLIC_DOMAIN` | empty | Generic domain (no scheme); `https://<PUBLIC_DOMAIN>` becomes the base URL. |
| `WEBHOOK_PATH` | `/webhook/gitcode` | Webhook route written into `server-config.json`. Change it when the git host is not GitCode. |
| `TRUSTED_HOSTS` | derived from the base URL | Host header allowlist; override only when serving behind an extra proxy. |
| `GRAPE_ENGINE_HOME` | `/app/data/engine-home` | Where the engine keeps its config, so it survives redeploys while `/app/data` is a volume. |
| `GRAPE_CONFIG_RAW_BASE` | `https://raw.githubusercontent.com/grape-dev/grape/main/configs` | Where missing `configs/*.json` seed files are fetched from if the image does not contain them. |
| `TEMPLATES_REPO` / `TEMPLATES_REF` | `https://github.com/grape-dev/grape-template.git` / `main` | Source of the project templates; both the git path and the tarball fallback follow these values. |
| `LLM_PROVIDER_ID` | `custom` | Provider key inside the engine config; keep it stable across redeploys. |

## 6. Volume and ports (platform settings, not variables)

| Setting | Value | Why |
|---|---|---|
| Volume mount | `/app/data` | Holds `sessions.db`, `.jwt_secret`, `engine-home/` and uploaded files. **Without this volume every redeploy regenerates the JWT secret (all users signed out) and loses the engine model config.** |
| Public port | `3000` | Must equal `GRAPE_PORT` and the Dockerfile `EXPOSE`. |
| Healthcheck | `/api/health`, timeout 300 s | Startup takes 10–40 s (template sync included); a shorter timeout can fail the first deploy. |