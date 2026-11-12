# Grape - single image definition for BOTH self-hosting and hosted platforms.
# Hosted-platform artifacts live in deploy/hosted/ (no vendor in the naming); this file serves both,
# so upstream changes to the image are picked up by hosted deployments automatically.
# Layer order follows change frequency: system/engine -> python deps -> templates -> source.
FROM python:3.12-slim

WORKDIR /app

# ---- 1) System deps + execution engine + codegraph (changes only when bumping versions) ----
# Engine versions are pinned so the image is reproducible: the provider schema changed between
# opencode 1.18.x and 1.19.x, and an unpinned build would silently pick up either.
ARG OPENCODE_VERSION=1.19.5
ARG CODEGRAPH_VERSION=1.6.2
# Template registry ref: defaults to the upstream branch; pass --build-arg TEMPLATES_REF=<tag> to pin.
ARG TEMPLATES_REF=main
# git/curl/ca-certificates: template sync and fallback downloads
# node 22: runtime for the opencode engine (and for codegraph)
# opencode-ai: the execution engine Grape drives (the npm package name is opencode-ai)
# codegraph: project-info generation engine (Issue #666), installed into its own prefix
# NOTE: node is intentionally NOT purged - the engine needs it at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc g++ git curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm i -g opencode-ai@${OPENCODE_VERSION} \
 && ( npm install -g --prefix /opt/codegraph @colbymchenry/codegraph@${CODEGRAPH_VERSION} \
      && ln -sf /opt/codegraph/bin/codegraph /usr/local/bin/codegraph \
      || echo "warning: codegraph install failed, project-info will run degraded with warning" ) \
 && npm cache clean --force \
 && rm -rf /var/lib/apt/lists/* \
 && ( codegraph --version \
      || ( echo "warning: codegraph unavailable, project-info will run degraded with warning"; rm -f /usr/local/bin/codegraph ) )

# ---- 2) Python dependencies (changes only with requirements.txt) ----
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- 3) Project templates (changes only with upstream grape-template; ~226 KB) ----
# The registry (configs/project-templates.json) and examples/ are not committed, and configs/ is
# excluded by .dockerignore, so they have to be baked in here - otherwise the UI template page is empty.
RUN mkdir -p /app/examples /app/configs \
 && curl -fsSL --retry 2 --max-time 180 \
      https://codeload.github.com/grape-dev/grape-template/tar.gz/refs/heads/${TEMPLATES_REF} -o /tmp/tpl.tgz \
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

# Disable public-IP probing in container environments
ENV GRAPE_AUTO_DETECT_URL=false

# ---- 5) Bootstrap ----
# The hosted bootstrap fills in the JWT secret (persisted on the volume), the public base URL and the
# engine model config from environment variables. It is inert unless it detects a hosted environment
# (or GRAPE_HOSTED_BOOTSTRAP=1), in which case it just execs the requested command - self-hosting is
# unaffected. COOKIE_SECURE is deliberately NOT set here: hosted platforms set it as a variable,
# while self-hosters on plain HTTP must keep it false or they cannot sign in.
COPY deploy/hosted/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "3000", "--proxy-headers", "--forwarded-allow-ips=*"]
