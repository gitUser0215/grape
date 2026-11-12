#!/bin/sh
# Grape · hosted-platform bootstrap (idempotent; platform env vars are the single source of truth)
#
# Fills in three things, all safe to re-run:
#   1) JWT_SECRET      - generate once and persist on the volume if absent
#                        (otherwise every redeploy rotates the key and logs everyone out)
#   2) public base URL - explicit SERVER_BASE_URL > generic PUBLIC_DOMAIN > platform-injected domain
#                        (RAILWAY_* is one example; other platforms set PUBLIC_DOMAIN or SERVER_BASE_URL)
#   3) engine config   - build $HOME/.config/opencode/opencode.json from the LLM_* variables
# Then hands control back to the original CMD.
set -eu

# Hosted bootstrap is opt-in: 1 = always, 0 = never, unset = auto-detect (hosted platform signals
# present). When it is off we simply exec the requested command, so self-hosting stays unchanged.
HOSTED="${GRAPE_HOSTED_BOOTSTRAP:-auto}"
if [ "$HOSTED" = "auto" ]; then
  if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] || [ -n "${RAILWAY_ENVIRONMENT_NAME:-}" ] \
     || [ -n "${RAILWAY_PROJECT_ID:-}" ] || [ -n "${PUBLIC_DOMAIN:-}" ] \
     || [ -n "${SERVER_BASE_URL:-}" ] || [ -n "${LLM_API_KEY:-}" ]; then
    HOSTED=1
  else
    HOSTED=0
  fi
fi
if [ "$HOSTED" != "1" ]; then
  echo "[entrypoint] hosted bootstrap disabled (GRAPE_HOSTED_BOOTSTRAP=$HOSTED) -> exec as-is"
  exec "$@"
fi

# Keep the engine home on the persistent volume when one is mounted, so model config survives redeploys.
# Without a volume (plain self-hosting) HOME is left untouched.
if [ -d /app/data ]; then
  export HOME="${GRAPE_ENGINE_HOME:-/app/data/engine-home}"
fi

DATA="${DEVOPS_DATA_DIR:-/app/data}"
mkdir -p "$DATA" /app/configs "$HOME/.config/opencode"

# ---------- 1) JWT_SECRET ----------
if [ -z "${JWT_SECRET:-}" ]; then
  if [ -f "$DATA/.jwt_secret" ]; then
    JWT_SECRET=$(cat "$DATA/.jwt_secret")
    JWT_SRC="volume"
  else
    JWT_SECRET=$(python3 -c 'import secrets;print(secrets.token_urlsafe(48))')
    printf '%s' "$JWT_SECRET" > "$DATA/.jwt_secret"
    chmod 600 "$DATA/.jwt_secret"
    JWT_SRC="generated"
  fi
  export JWT_SECRET
  echo "[entrypoint] JWT_SECRET <- ${JWT_SRC}"
fi

# ---------- 2) Public base URL ----------
# configs/ is excluded by .dockerignore, so it has to be created at runtime.
# Priority: explicit SERVER_BASE_URL > generic PUBLIC_DOMAIN > platform-injected RAILWAY_PUBLIC_DOMAIN.
BASE_URL=""
BASE_SRC=""
if [ -n "${SERVER_BASE_URL:-}" ]; then
  BASE_URL="${SERVER_BASE_URL%/}"; BASE_SRC="SERVER_BASE_URL"
elif [ -n "${PUBLIC_DOMAIN:-}" ]; then
  BASE_URL="https://${PUBLIC_DOMAIN}"; BASE_SRC="PUBLIC_DOMAIN"
elif [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"; BASE_SRC="RAILWAY_PUBLIC_DOMAIN"
fi
if [ -n "$BASE_URL" ]; then
  # The webhook route differs per git host (GitCode lives under /webhook/gitcode); override for others.
  WEBHOOK_PATH="${WEBHOOK_PATH:-/webhook/gitcode}"
  printf '{"server_base_url":"%s","webhook_url":"%s%s"}\n' \
    "$BASE_URL" "$BASE_URL" "$WEBHOOK_PATH" > /app/configs/server-config.json
  HOST="${BASE_URL#http://}"; HOST="${HOST#https://}"; HOST="${HOST%%/*}"
  export TRUSTED_HOSTS="${TRUSTED_HOSTS:-$HOST}"
  echo "[entrypoint] server_base_url <- ${BASE_SRC} (${BASE_URL})"
else
  echo "[entrypoint] WARN: neither SERVER_BASE_URL nor PUBLIC_DOMAIN / RAILWAY_PUBLIC_DOMAIN is available - server-config.json not written; OAuth callbacks will point at localhost:3000" >&2
fi

# ---------- 3) Project templates pre-sync (idempotent) ----------
# Grape's template registry (configs/project-templates.json) and examples/ are not committed;
# scripts/sync_templates.sh generates them from the grape-template repository. Without them the
# UI template page is empty. We sync once at startup: try the shell script (needs git) first,
# fall back to a codeload tarball (no git required).
if [ ! -s /app/configs/project-templates.json ] || [ ! -d /app/examples ] || [ -z "$(find /app/examples -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)" ]; then
  TPL_REPO="${TEMPLATES_REPO:-https://github.com/grape-dev/grape-template.git}"
  TPL_REF="${TEMPLATES_REF:-main}"
  echo "[entrypoint] templates missing -> syncing from ${TPL_REPO}@${TPL_REF}"
  if command -v git >/dev/null 2>&1 && TEMPLATES_REPO="$TPL_REPO" TEMPLATES_REF="$TPL_REF" bash /app/scripts/sync_templates.sh; then
    echo "[entrypoint] templates synced (git)"
  else
    TPL_STAGE=$(mktemp -d)
    # Derive owner/repo from TEMPLATES_REPO so a mirror or fork override also applies to the fallback.
    TPL_SLUG=$(printf '%s' "$TPL_REPO" | sed -e 's#^.*github\.com[/:]##' -e 's#\.git$##')
    TPL_TB="https://codeload.github.com/${TPL_SLUG:-grape-dev/grape-template}/tar.gz/refs/heads/${TPL_REF}"
    if curl -fsSL --retry 2 --max-time 120 "$TPL_TB" -o "$TPL_STAGE/t.tgz" && tar xzf "$TPL_STAGE/t.tgz" -C "$TPL_STAGE"; then
      TPL_SRC=$(find "$TPL_STAGE" -mindepth 1 -maxdepth 1 -type d -name 'grape-template-*' | head -1)
      mkdir -p /app/examples /app/configs
      for d in "$TPL_SRC"/*/; do
        n=$(basename "$d"); [ "$n" = ".git" ] && continue
        rm -rf "/app/examples/$n"; cp -a "$d" "/app/examples/$n"
      done
      if [ -f "$TPL_SRC/project-templates.json" ]; then
        cp -a "$TPL_SRC/project-templates.json" /app/configs/project-templates.json
      fi
      echo "[entrypoint] templates synced (tarball)"
    else
      echo "[entrypoint] WARN: template sync failed (template page may be empty); starting anyway" >&2
    fi
    rm -rf "$TPL_STAGE"
  fi
else
  echo "[entrypoint] templates present (skip sync)"
fi

# ---------- 3b) Official config seeds (agent types / pipelines / ...) ----------
# configs/*.json are excluded from the build context by the upstream .dockerignore, so a container
# built from this repo has no /app/configs/*.json at all. Consequences: Grape cannot seed the
# agent_type table (the Agents page then fails with "Agent type not configured: vod") and several
# defaults are missing. Fetch whichever seed files are absent from the public repo (best effort).
CFG_BASE="${GRAPE_CONFIG_RAW_BASE:-https://raw.githubusercontent.com/grape-dev/grape/main/configs}"
for _f in agent-description.json agent-skill-mapping.json default-scene.json engine-selection.json \
          pipelines.json credential-filter.json onboarding-templates.json; do
  [ -s "/app/configs/$_f" ] && continue
  if curl -fsSL --retry 2 --max-time 30 "$CFG_BASE/$_f" -o "/app/configs/$_f"; then
    echo "[entrypoint] config seed fetched: $_f"
  else
    rm -f "/app/configs/$_f"
    echo "[entrypoint] WARN: config seed unavailable: $_f" >&2
  fi
done

# ---------- 4) Engine model config (opencode provider shape verified working) ----------
# Why not the top-level `providers` form: opencode 1.18.x only understands the classic
# `provider.<id>` block with `npm` (not `package`) + `options.baseURL`, and the npm package must be
# @ai-sdk/openai-compatible. Using `providers` + `package` + a top-level baseURL yields
# "Provider not found" / "Failed to initialize provider". Verified working against a real gateway.
if [ -n "${LLM_API_KEY:-}" ]; then
  CFG="$HOME/.config/opencode/opencode.json"
  mkdir -p "$(dirname "$CFG")"
  PID="${LLM_PROVIDER_ID:-custom}"
  # Provider presets: LLM_PROVIDER + LLM_API_KEY is enough to be usable out of the box.
  # Every preset below speaks the OpenAI-compatible protocol (the engine is configured with
  # @ai-sdk/openai-compatible). Anything else: leave LLM_PROVIDER empty and set LLM_BASE_URL.
  # Providers without a /models endpoint are flagged, so we skip a discovery call that cannot succeed
  # and ask for LLM_MODEL instead.
  NO_MODEL_LIST=0
  case "${LLM_PROVIDER:-}" in
    openai)     DEF_BASE="https://api.openai.com/v1" ;;
    openrouter) DEF_BASE="https://openrouter.ai/api/v1" ;;
    gemini)     DEF_BASE="https://generativelanguage.googleapis.com/v1beta/openai" ;;
    groq)       DEF_BASE="https://api.groq.com/openai/v1" ;;
    anthropic)  DEF_BASE="https://api.anthropic.com/v1"; NO_MODEL_LIST=1 ;;
    deepseek)   DEF_BASE="https://api.deepseek.com/v1" ;;
    opengw)     DEF_BASE="https://opengw.clouddeveloper.club/v1" ;;
    *)          DEF_BASE="" ;;
  esac
  BASE="${LLM_BASE_URL:-$DEF_BASE}"
  if [ -z "$BASE" ]; then
    echo "[entrypoint] WARN: neither LLM_BASE_URL nor an LLM_PROVIDER preset was given; the engine may not resolve an endpoint" >&2
  fi
  LLM_BASE_URL="$BASE" \
  LLM_MODEL_ID="${LLM_MODEL:-}" \
  LLM_PROVIDER_ID="$PID" \
  LLM_NO_MODEL_LIST="$NO_MODEL_LIST" \
  OPENCODE_CFG="$CFG" \
  python3 - <<'PY'
import json, os, sys, urllib.request

base = (os.environ.get("LLM_BASE_URL") or "").strip()
mid = (os.environ.get("LLM_MODEL_ID") or "").strip()
pid = (os.environ.get("LLM_PROVIDER_ID") or "custom").strip() or "custom"
cfg_path = os.environ["OPENCODE_CFG"]
api_key = os.environ.get("LLM_API_KEY") or ""

# LLM_MODEL may be `custom/<model-id>` or a bare `<model-id>`; we keep the part after the slash
mid = mid.split("/", 1)[1] if "/" in mid else mid

models = {}
def add(m):
    m = (m or "").strip()
    if m and m not in models:
        models[m] = {"name": m}

add(mid)

# If the endpoint exposes /models, register every model it returns, so deployers can switch
# between models in Grape's Agent Settings instead of being pinned to a single one.
no_list = os.environ.get("LLM_NO_MODEL_LIST") == "1"
if base and not no_list:
    try:
        req = urllib.request.Request(
            base.rstrip("/") + "/models",
            headers={"Authorization": f"Bearer {api_key}"},
        )
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read().decode())
        for item in (data.get("data") or []):
            add(item.get("id"))
    except Exception as e:
        print(f"[entrypoint] model discovery skipped: {type(e).__name__}: {e}", file=sys.stderr)

if not models:
    print(
        "[entrypoint] ERROR: no model available - the endpoint returned no model list, or the discovery call failed, and LLM_MODEL is empty.\n"
        "[entrypoint]        set LLM_MODEL explicitly, e.g. claude-sonnet-4-5 for the anthropic preset.",
        file=sys.stderr,
    )
    sys.exit(0)

# When no model was given, prefer a strong general-purpose model over the alphabetically first one
# (an aggregator endpoint such as OpenRouter lists hundreds of models in arbitrary order).
PREFERRED = [
    "claude-sonnet-4-5", "claude-sonnet-4", "claude-3-7-sonnet",
    "gpt-5", "gpt-4.1", "gemini-2.5-pro", "deepseek-chat", "deepseek-v3",
    "qwen3-coder", "llama-3.3-70b",
]


def pick_default(available):
    lowered = {m.lower(): m for m in available}
    for pref in PREFERRED:
        for k, m in lowered.items():
            if pref in k:
                return m
    return sorted(available)[0]


default_model = f"{pid}/{mid}" if mid else f"{pid}/{pick_default(models)}"
provider = {
    "npm": "@ai-sdk/openai-compatible",
    "options": {"apiKey": "{env:LLM_API_KEY}"},
    "models": models,
}
if base:
    provider["options"]["baseURL"] = base

cfg = {
    "$schema": "https://opencode.ai/config.json",
    "model": default_model,
    "provider": {pid: provider},
}
with open(cfg_path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
print(
    f"[entrypoint] engine config -> {cfg_path} "
    f"(provider={pid} default={default_model} models={len(models)} baseURL={base or '<unset>'})"
)
PY
else
  echo "[entrypoint] LLM_API_KEY not provided: skipping engine config; tasks will report \"no available engine\"" >&2
fi

# ---------- 5) Hand control back to the original CMD ----------
exec "$@"
