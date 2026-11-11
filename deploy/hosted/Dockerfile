# Grape · 托管平台一键部署镜像（与主 Dockerfile 并存，不影响自建部署）
# 目录 deploy/hosted/ 存放所有「托管平台」相关的构建与上架材料，与具体厂商解耦。
#
# 层顺序按「变化频率」排：系统/引擎 → Python 依赖 → 项目模板 → 源码。
# 只改源码时，前三层全部命中缓存，重建时间主要花在 COPY + 启动校验上。
FROM python:3.12-slim

WORKDIR /app

# ---- 1) 系统依赖 + 执行引擎（改动极少：只有换 Node/引擎版本才会失效）----
# git 供 scripts/sync_templates.sh 使用；curl/ca-certificates 供兜底下载与健康检查。
# opencode-ai 是引擎的正确 npm 包名（npm 上的 `opencode` 不存在）。
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc g++ git curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm i -g opencode-ai \
 && npm cache clean --force \
 && rm -rf /var/lib/apt/lists/*

# ---- 2) Python 依赖（只随 requirements.txt 变化）----
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- 3) 项目模板（只随 grape-template 上游变化；约 226 KB，烘进镜像后运行时无需同步）----
# Grape 的模板注册表不在本仓库，缺了会导致前端「项目模板」页为空。
RUN mkdir -p /app/examples /app/configs \
 && curl -fsSL --retry 2 --max-time 180 \
      https://codeload.github.com/grape-dev/grape-template/tar.gz/refs/heads/main -o /tmp/tpl.tgz \
 && tar xzf /tmp/tpl.tgz -C /tmp \
 && SRC=$(find /tmp -mindepth 1 -maxdepth 1 -type d -name 'grape-template-*' | head -1) \
 && for d in "$SRC"/*/; do n=$(basename "$d"); [ "$n" = ".git" ] && continue; cp -a "$d" "/app/examples/$n"; done \
 && cp -a "$SRC/project-templates.json" /app/configs/project-templates.json \
 && rm -rf /tmp/tpl.tgz "$SRC"

# ---- 4) 源码（改动最频繁，放最后一层）----
COPY . .
COPY .env.example .env

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 内网/容器环境关闭公网 IP 探测（沿用主 Dockerfile 的设定）
ENV GRAPE_AUTO_DETECT_URL=false
ENV COOKIE_SECURE=true

# 引擎家目录必须落在持久卷上，否则重部署丢模型配置
ENV HOME=/app/data/engine-home

# ---- 5) 启动引导（按平台变量补齐 JWT / 对外基址 / 引擎配置，幂等）----
COPY deploy/hosted/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "3000", "--proxy-headers", "--forwarded-allow-ips=*"]
