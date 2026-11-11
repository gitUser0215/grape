#!/bin/sh
# Grape · hosted-platform bootstrap (idempotent; platform env vars are the single source of truth)
#
# Fills in three things, all safe to re-run:
#   1) JWT_SECRET      - generate once and persist on the volume if absent
#                        (otherwise every redeploy rotates the key and logs everyone out)
#   2) public base URL - explicit SERVER_BASE_URL > generic PUBLIC_DOMAIN > platform-injected RAILWAY_PUBLIC_DOMAIN
#   3) engine config   - build $HOME/.config/opencode/opencode.json from the LLM_* variables
# Then hands control back to the original CMD.
set -eu

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
elif [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"; BASE_SRC="RAILWAY_PUBLIC_DOMAIN"
fi
if [ -n "$BASE_URL" ]; then
  printf '{"server_base_url":"%s","webhook_url":"%s/webhook/gitcode"}\n' \
    "$BASE_URL" "$BASE_URL" > /app/configs/server-config.json
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
    TPL_TB="https://codeload.github.com/grape-dev/grape-template/tar.gz/refs/heads/${TPL_REF}"
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

# ---------- 4) Engine model config (opencode provider shape verified working) ----------
# Why not the top-level `providers` form: opencode 1.18.x only understands the classic
# `provider.<id>` block with `npm` (not `package`) + `options.baseURL`, and the npm package must be
# @ai-sdk/openai-compatible. Using `providers` + `package` + a top-level baseURL yields
# "Provider not found" / "Failed to initialize provider". Verified working against a real gateway.
if [ -n "${LLM_API_KEY:-}" ]; then
  CFG="$HOME/.config/opencode/opencode.json"
  mkdir -p "$(dirname "$CFG")"
  PID="${LLM_PROVIDER_ID:-custom}"
  # provider presets: LLM_PROVIDER + LLM_API_KEY is enough to be usable out of the box
  case "${LLM_PROVIDER:-}" in
    openai)     DEF_BASE="https://api.openai.com/v1" ;;
    deepseek)   DEF_BASE="https://api.deepseek.com/v1" ;;
    openrouter) DEF_BASE="https://openrouter.ai/api/v1" ;;
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
if base:
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
    print("[entrypoint] no model given and endpoint returned no model list; skipping engine config", file=sys.stderr)
    sys.exit(0)

default_model = f"{pid}/{mid}" if mid else f"{pid}/{sorted(models)[0]}"
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
