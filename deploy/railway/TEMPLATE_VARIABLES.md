# Railway 模板变量表（照此填进 Template Composer）

> 原则：**表单里只留一个必填**（`LLM_API_KEY`），其余要么预置、要么用模板变量函数生成、要么带默认值。
> Railway 官方 best practices 原文要求：每个变量都要写描述；密钥必须用 `secret()` 生成，禁止硬编码默认凭据。

## 1. 可见变量（部署者在部署表单里会看到）

| 变量名 | 可见性 / 必填 | 值 | 描述（直接复制到 Description 字段） |
|---|---|---|---|
| `LLM_API_KEY` | **必填（required）** | 留空，由部署者填 | 你的模型服务密钥（OpenAI 兼容端点）。不填也能部署并登录，但 Agent 任务无法执行 |
| `JWT_SECRET` | 可见 | `${{secret(64)}}` | 自动生成的会话签名密钥，**请勿修改**（改了会让所有已登录用户失效） |
| `GRAPE_ADMIN_PASSWORD` | 可见 | `${{secret(24)}}` | 管理台 `/admin` 的登录密码，可在 Variables 页查看；建议部署后改成自己的 |
| `LLM_BASE_URL` | 可选 | 空 | OpenAI 兼容端点，例如 `https://<你的网关>/v1`。留空则使用执行引擎内置 provider 目录中的端点 |
| `LLM_MODEL` | 可选 | 空 | 模型标识，形如 `custom/<模型ID>`；前缀必须与 `LLM_PROVIDER_ID` 一致。留空则部署后在「Agent 配置」里选择 |
| `LLM_PROVIDER_ID` | 可选（高级） | `custom` | provider 标识，仅当你要给端点起自定义名字时修改；修改后 `LLM_MODEL` 前缀要同步改 |

## 2. 隐形变量（预置，不暴露给部署者填写）

| 变量名 | 值 | 说明 |
|---|---|---|
| `COOKIE_SECURE` | `true` | 平台全站 HTTPS，必须为 true（Grape 生产门禁会校验） |
| `GRAPE_PORT` | `3000` | 与容器监听端口、模板公网端口保持一致 |
| `DEVOPS_DB_BACKEND` | `sqlite` | 默认 SQLite，数据落在卷 `/app/data` |
| `COOKIE_SECURE` 之外的 cookie 项 | — | 不需要 |

## 3. 由平台注入、**不要手工填写**的系统变量

| 变量 | 来源 | Grape 用途 |
|---|---|---|
| `RAILWAY_PUBLIC_DOMAIN` | Railway 自动注入（生成域名后存在） | 容器启动时由 entrypoint 推导 `server_base_url` 与 `TRUSTED_HOSTS` |
| `RAILWAY_PRIVATE_DOMAIN` / `RAILWAY_*` 其余项 | Railway 自动注入 | Grape 不使用 |

## 4. 可选兜底变量（仅排障时使用）

| 变量 | 何时用 |
|---|---|
| `SERVER_BASE_URL` | 当平台没注入 `RAILWAY_PUBLIC_DOMAIN`（例如域名是在容器启动之后才生成的）时，显式指定 `https://<你的域名>`。**优先级高于** `RAILWAY_PUBLIC_DOMAIN`。正常情况下留空，不要写死域名 |
| `TRUSTED_HOSTS` | 默认由 entrypoint 从基址推导；反向代理链异常时可显式指定主机名 |

## 5. 模板结构（Composer 里要配的编排）

| 项 | 值 |
|---|---|
| Service source | `https://github.com/<your-org>/grape`（默认分支 `main`） |
| Public Networking | **Enable**，HTTP，端口 `3000`（预置后部署时即生成域名，`RAILWAY_PUBLIC_DOMAIN` 首启可读） |
| Volume | Attach，mount path **`/app/data`** |
| Region | **不固定**（不写 `deploy.region`），让部署者用自己的默认区域 |
| Health check | `/api/health`（已由 `railway.json` 指定，超时 300 s） |

## 6. 生成函数速查（官方仅提供两个）

| 函数 | 说明 | 例子 |
|---|---|---|
| `secret(length?, alphabet?)` | 生成随机密钥，默认 32 字符 | `${{secret(64)}}`、`${{secret(64, "abcdef0123456789")}}`（hex 风格） |
| `randomInt(min?, max?)` | 生成区间内的随机整数，默认 0–100 | `${{randomInt(1, 65535)}}` |
