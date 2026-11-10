#!/bin/sh
# Grape · 托管平台启动引导（幂等；配置唯一真相源＝平台环境变量）
set -eu

DATA="${DEVOPS_DATA_DIR:-/app/data}"
mkdir -p "$DATA" /app/configs "$HOME/.config/opencode"

# (1) JWT_SECRET：未提供则生成一次并落卷（否则重部署换密钥、登录全失效）
if [ -z "${JWT_SECRET:-}" ]; then
  if [ -f "$DATA/.jwt_secret" ]; then
    JWT_SECRET=$(cat "$DATA/.jwt_secret")
  else
    JWT_SECRET=$(python3 -c 'import secrets;print(secrets.token_urlsafe(48))')
    printf '%s' "$JWT_SECRET" > "$DATA/.jwt_secret"
    chmod 600 "$DATA/.jwt_secret"
  fi
  export JWT_SECRET
fi

# (2) 对外基址：由平台注入的域名推导（部署者无需进 /admin 手填）
#     configs/ 被 .dockerignore 排除，因此必须运行时创建
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  printf '{"server_base_url":"https://%s","webhook_url":"https://%s/webhook/gitcode"}\n' \
    "$RAILWAY_PUBLIC_DOMAIN" "$RAILWAY_PUBLIC_DOMAIN" > /app/configs/server-config.json
  export TRUSTED_HOSTS="${TRUSTED_HOSTS:-$RAILWAY_PUBLIC_DOMAIN}"
fi

# (3) 引擎配置：不写死任何厂商/模型，按部署者提供的变量组装
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

# (4) 交回原启动命令
exec "$@"
