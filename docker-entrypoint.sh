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

# ---------- 3) 引擎模型配置 ----------
# 不写死任何厂商/模型：写什么由部署者提供的变量决定。
if [ -n "${LLM_API_KEY:-}" ]; then
  CFG="$HOME/.config/opencode/opencode.json"
  PID="${LLM_PROVIDER_ID:-custom}"
  {
    printf '{\n  "$schema": "https://opencode.ai/config.json"'
    if [ -n "${LLM_MODEL:-}" ]; then printf ',\n  "model": "%s"' "$LLM_MODEL"; fi
    printf ',\n  "providers": {\n    "%s": {\n      "env": ["LLM_API_KEY"]' "$PID"
    if [ -n "${LLM_BASE_URL:-}" ]; then printf ',\n      "baseURL": "%s"' "$LLM_BASE_URL"; fi
    printf ',\n      "package": "@opencode/ai/providers/openai-compatible"\n    }\n  }\n}\n'
  } > "$CFG"
  echo "[entrypoint] engine config -> $CFG (provider=$PID model=${LLM_MODEL:-<unset>} baseURL=${LLM_BASE_URL:-<unset>})"
else
  echo "[entrypoint] LLM_API_KEY 未提供：跳过引擎配置，任务将提示「无可用引擎」" >&2
fi

# ---------- 4) 交回原启动命令 ----------
exec "$@"
