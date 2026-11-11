![](https://raw.githubusercontent.com/gitUser0215/grape/main/deploy/railway/icon.png)

# Deploy Grape

AI-native DevOps platform: agent-driven pipelines, a shared skill library and repository hosting

## Deploy and Host Grape

Grape 是一个 AI 原生 DevOps 平台。它把研发流程（需求、任务、评审、发布）映射成可被 Agent 执行的任务，并把技能库、项目模板与仓库托管统一到一个 WebUI 里。

### About Hosting Grape

本模板用仓库根目录的 `Dockerfile.railway` 构建**单个服务**，监听 **3000** 端口，自动签发 HTTPS 域名。

- **持久化存储（Persistent Storage）**：卷挂载到 `/app/data`，SQLite 会话库、技能存储、执行引擎家目录与日志都在这里，重部署不丢。
- **开箱即用（Ready-to-Use Defaults）**：只需填 `LLM_API_KEY`（要指定厂商可再填 `LLM_PROVIDER`）。`JWT_SECRET` 由模板变量函数自动生成，对外基址（`server_base_url`）在容器启动时从平台域名推导，**模型列表也会在启动时自动从端点枚举**，无需手填模型名。
- **浏览器内完成引导（Browser-Only Bootstrap）**：无需 CLI。打开域名 → 用户名 + 密码注册（未配置邮箱时自动跳过验证码）→ 直接可用。

### Common Use Cases

- 把 Issue / PR 流转自动化成 Agent 任务
- 用统一技能库沉淀团队研发规范
- 给多个仓库挂同一套流水线与评审规则
- 作为团队内部 AI 研发助手的统一入口

### Dependencies for Grape Hosting

- 一个模型服务密钥 `LLM_API_KEY`（OpenAI 兼容端点）：厂商直连（配 `LLM_PROVIDER=openai|deepseek|openrouter`）或自建网关（配 `LLM_BASE_URL`）
- **不需要**自己安装执行引擎：镜像内已预装 `opencode`（唯一预置引擎，API key 型，开箱即用）
- 平台自动开通的持久卷，挂载到 `/app/data`

### Why Deploy Grape on Railway?

Railway 把 Grape 的服务、容器启动引导、公网 HTTPS 域名与持久卷打包成一次点击的部署：你不需要准备服务器、不需要配 nginx、不需要进容器改配置。填一个 `LLM_API_KEY` 后，注册、登录、创建仓库、跑第一个 Agent 任务都在浏览器里完成，同时保留对环境变量、实时日志、指标和扩缩容的完全控制。

### 部署后要做的三件事

1. 打开域名，用**用户名 + 密码注册**（注册成功即登录）
2. 进 `/admin`，用 `GRAPE_ADMIN_PASSWORD` 登录（该值在 Variables 页可查看），改掉初始密码
3. 在「Agent 配置」里确认执行引擎在线（本模板已内置 `opencode`），从列表里选择模型（列表由容器启动时自动枚举端点全部可用模型）

### 常见故障

| 现象 | 原因 | 处理 |
|---|---|---|
| 页面能开，提交任务提示「无可用引擎」 | 没填 `LLM_API_KEY` | 在 Variables 里补 `LLM_API_KEY`（可选 `LLM_BASE_URL` / `LLM_MODEL`），保存后自动重部署 |
| 任务失败，日志里是鉴权 / 404 | key 与端点不匹配 | 检查 `LLM_BASE_URL` 是否带 `/v1`；用预设时检查 `LLM_PROVIDER` 拼写 |
| 「Agent 配置」里模型列表为空，或报 `Failed to initialize provider` | 引擎配置未生成（缺 key）或端点不可达 | 看容器日志是否出现 `[entrypoint] engine config ->` 且 `models=` 大于 0；缺 key 时先补 `LLM_API_KEY` |
| `server_base_url` 指向 `localhost:3000` | 域名在容器启动后才生成 | 点一次 `Redeploy`；或显式设置 `SERVER_BASE_URL=https://<你的域名>` |
| OAuth 登录回跳失败 | 回调地址未登记 | 若要 GitCode / GitHub 登录，把 `https://<你的域名>/api/auth/callback/{gitcode,github}` 登记到对应 OAuth App |
| 重启后登录态丢失 / 数据没了 | 卷未挂载或挂错路径 | 确认卷挂载路径为 `/app/data` |

### 模型与端点怎么填（三选一）

| 你的情况 | 要填的变量 |
|---|---|
| OpenAI 官方 key | `LLM_API_KEY` + `LLM_PROVIDER=openai` |
| DeepSeek / OpenRouter | `LLM_API_KEY` + `LLM_PROVIDER=deepseek`（或 `openrouter`） |
| 自建 / 公司网关 | `LLM_API_KEY` + `LLM_BASE_URL=https://<你的网关>/v1` |

想固定默认模型时再加 `LLM_MODEL=<模型ID>`（写 `custom/<模型ID>` 也可以）。
**留空 `LLM_MODEL` 是推荐用法**：容器启动会把端点 `/v1/models` 返回的全部模型注册进来，部署后可在「Agent 配置」里随时切换，不会被钉死在单一模型上。

### 执行引擎：本模板只预置 1 个

镜像内只预装 `opencode` 一个执行引擎（`npm i -g opencode-ai`）。它是唯一"只给一个 API key 就能跑"的引擎，最适合公开模板。

想用其它引擎（AIShell / Codex / dsh / CodeArts 等）：在**你自己的机器**上安装对应 CLI，用 Grape 的 `rta_` token 注册为**远端 worker**，任务会路由到那台机器执行 —— 容器里不需要额外引擎，也不会撑大镜像。

### 升级策略（不会自动升级）

本模板**不会自动更新**。后续代码更新需要你确认才会生效：

1. 模板作者合并更新后，你的 Railway 项目里会出现「有更新可用」的通知；
2. 升级前先看 [CHANGELOG](https://github.com/gitUser0215/grape/blob/main/deploy/railway/TEMPLATE_CHANGELOG.md)，确认改了什么、是否需要手动配合；
3. 确认后用通知里的 **Apply** 应用；不确认就一直保持当前版本，不受影响。

补充说明：

- 服务默认 `Settings → Source → Auto deploy` 为 **Disabled**（模板部署的默认状态）。保持关闭即"推送只进仓库、上线由你点"；开启则每次推送都会自动部署。
- 数据在卷 `/app/data` 上，升级不丢数据，但**升级过程有短暂停机**（数十秒）。
- 回滚：Deployments 里可回退到历史部署（保留期有限，建议升级后观察一段时间）。
- 想自己改源码：服务 `Settings → Source → Eject`，把仓库复制到你的 GitHub 账号后再改。

### 容器参数（部署时自动带上）

| 项 | 值 |
|---|---|
| 构建 | 仓库根目录 `Dockerfile.railway`（由 `railway.json` 指定） |
| 端口 | `3000` |
| 卷 | `/app/data` |
| 健康检查 | `/api/health`（超时 300 s） |
| 区域 | 未固定，按部署者账号的默认区域 |

### References

- 项目主页与文档：仓库 `README.zh.md`
- 生产部署说明：`docs/DEPLOYMENT.zh.md`
- 平台配置（OAuth / 机器人 / 引擎与模型）：`docs/CONFIGURATION.zh.md`
