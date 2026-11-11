#!/bin/sh
# Grape · 托管平台启动引导（幂等；配置唯一真相源＝平台环境变量）
#
# 自动补齐三件事，全部可安全重复执行：
#   1) JWT_SECRET      —— 未提供则生成一次并落卷（否则重部署换密钥、登录全失效）
#   2) server base url —— 显式 SERVER_BASE_URL 优先，其次平台注入的 RAILWAY_PUBLIC_DOMAIN
#   3) 引擎模型配置    —— 按 LLM_* 变量组装 $HOME/.config/opencode/opencode.json
# 之后把控制权交回原 CMD。
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

# ---------- 2) 对外基址 ----------
# configs/ 被 .dockerignore 排除，所以必须运行时创建。
# 优先级：显式 SERVER_BASE_URL > 平台注入的 RAILWAY_PUBLIC_DOMAIN。
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
  echo "[entrypoint] 警告: 既未提供 SERVER_BASE_URL，也拿不到 RAILWAY_PUBLIC_DOMAIN —— 未生成 server-config.json，OAuth 回调将指向 localhost:3000" >&2
fi

# ---------- 3) 项目模板预同步（幂等）----------
# Grape 的模板注册表 configs/project-templates.json 与 examples/ 不在仓库里，
# 由 scripts/sync_templates.sh 从 grape-template 仓库同步生成。镜像内没有它 → 前端模板页为空。
# 这里在启动时补一次：优先 svn 脚本（需 git），失败则退回 codeload tarball（不依赖 git）。
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
      echo "[entrypoint] 警告: 模板同步失败（模板页可能为空），应用仍会启动" >&2
    fi
    rm -rf "$TPL_STAGE"
  fi
else
  echo "[entrypoint] templates present (skip sync)"
fi

# ---------- 4) 引擎模型配置（实测可用的 opencode provider 形态）----------
# 为什么不用 `providers` 顶层写法：opencode 1.18.x 只认旧式 `provider.<id>.options.baseURL`
# 与 `npm`（不是 `package`）字段，包名必须是 @ai-sdk/openai-compatible；
# 写成 providers + package + 顶层 baseURL 会报 "Provider not found / Failed to initialize provider"
# （2026-11-11 本机实测：该形态可直接调通网关并返回结果）。
if [ -n "${LLM_API_KEY:-}" ]; then
  CFG="$HOME/.config/opencode/opencode.json"
  mkdir -p "$(dirname "$CFG")"
  PID="${LLM_PROVIDER_ID:-custom}"
  # provider 预设：只填 LLM_PROVIDER + LLM_API_KEY 即可开箱可用
  case "${LLM_PROVIDER:-}" in
    openai)     DEF_BASE="https://api.openai.com/v1" ;;
    deepseek)   DEF_BASE="https://api.deepseek.com/v1" ;;
    openrouter) DEF_BASE="https://openrouter.ai/api/v1" ;;
    opengw)     DEF_BASE="https://opengw.clouddeveloper.club/v1" ;;
    *)          DEF_BASE="" ;;
  esac
  BASE="${LLM_BASE_URL:-$DEF_BASE}"
  if [ -z "$BASE" ]; then
    echo "[entrypoint] 警告: 未指定 LLM_BASE_URL 也未给 LLM_PROVIDER 预设，引擎可能无法解析端点" >&2
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

# LLM_MODEL 允许写成 custom/<模型ID> 或裸 <模型ID>，统一取后半段作为模型 ID
mid = mid.split("/", 1)[1] if "/" in mid else mid

models = {}
def add(m):
    m = (m or "").strip()
    if m and m not in models:
        models[m] = {"name": m}

add(mid)

# 端点若有 /models 清单，则把全部模型注册进来 —— 这样部署者可在
# Grape「Agent 配置」里自由切换多个大模型，而不是被钉在单一模型上。
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
    print("[entrypoint] 未提供模型且端点未返回模型清单，跳过引擎配置", file=sys.stderr)
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
  echo "[entrypoint] LLM_API_KEY 未提供：跳过引擎配置，任务将提示「无可用引擎」" >&2
fi

# ---------- 5) 交回原启动命令 ----------
exec "$@"
