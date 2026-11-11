# Grape - one-click image for hosted platforms (sits next to the main Dockerfile; self-hosting unaffected)
# deploy/hosted/ holds every hosted-platform artifact (build + listing) with no vendor in the naming.
#
# Layer order follows change frequency: system/engine -> Python deps -> project templates -> source.
# Touching only source code keeps the first three layers cached.
FROM python:3.12-slim

WORKDIR /app

# ---- 1) System deps + execution engine (rarely changes: only when bumping Node/engine) ----
# git is used by scripts/sync_templates.sh; curl/ca-certificates for fallback downloads and health checks.
# opencode-ai is the correct npm package name (there is no `opencode` package on npm).
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc g++ git curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm i -g opencode-ai \
 && npm cache clean --force \
 && rm -rf /var/lib/apt/lists/*

# ---- 2) Python dependencies (changes only with requirements.txt) ----
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- 3) Project templates (changes only with upstream grape-template; ~226 KB baked in,
# so no runtime sync is needed). The registry is not in this repo; without it the UI template page is empty. ----
RUN mkdir -p /app/examples /app/configs \
 && curl -fsSL --retry 2 --max-time 180 \
      https://codeload.github.com/grape-dev/grape-template/tar.gz/refs/heads/main -o /tmp/tpl.tgz \
 && tar xzf /tmp/tpl.tgz -C /tmp \
 && SRC=$(find /tmp -mindepth 1 -maxdepth 1 -type d -name 'grape-template-*' | head -1) \
 && for d in "$SRC"/*/; do n=$(basename "$d"); [ "$n" = ".git" ] && continue; cp -a "$d" "/app/examples/$n"; done \
 && cp -a "$SRC/project-templates.json" /app/configs/project-templates.json \
 && rm -rf /tmp/tpl.tgz "$SRC"

# ---- 4) Source code (changes most often, so it goes last) ----
COPY . .
COPY .env.example .env

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Disable public-IP probing in container environments (same as the main Dockerfile)
ENV GRAPE_AUTO_DETECT_URL=false
ENV COOKIE_SECURE=true

# The engine home directory must live on the persistent volume, otherwise model config is lost on redeploy
ENV HOME=/app/data/engine-home

# ---- 5) Bootstrap (fills in JWT / public base URL / engine config from platform env vars; idempotent) ----
COPY deploy/hosted/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "3000", "--proxy-headers", "--forwarded-allow-ips=*"]
