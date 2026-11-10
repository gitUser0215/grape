![](https://raw.githubusercontent.com/gitUser0215/grape/main/deploy/railway/icon.png)

# Deploy Grape

AI-native DevOps platform: agent-driven pipelines, a shared skill library and repository hosting

## Deploy and Host Grape

Grape 是一个 AI 原生 DevOps 平台。它把研发流程（需求、任务、评审、发布）映射成可被 Agent 执行的任务，并把技能库、项目模板与仓库托管统一到一个 WebUI 里。

### About Hosting Grape

本模板用仓库根目录的 `Dockerfile.railway` 构建**单个服务**，监听 **3000** 端口，自动签发 HTTPS 域名。

- **持久化存储（Persistent Storage）**：卷挂载到 `/app/data`，SQLite 会话库、技能存储、执行引擎家目录与日志都在这里，重部署不丢。
- **开箱即用（Ready-to-Use Defaults）**：只需填 `LLM_API_KEY`。`JWT_SECRET` 由模板变量函数自动生成，对外基址（`server_base_url`）在容器启动时从平台域名推导，无需手填地址。
- **浏览器内完成引导（Browser-Only Bootstrap）**：无需 CLI。打开域名 → 用户名 + 密码注册（未配置邮箱时自动跳过验证码）→ 直接可用。

### Common Use Cases

- 把 Issue / PR 流转自动化成 Agent 任务
- 用统一技能库沉淀团队研发规范
- 给多个仓库挂同一套流水线与评审规则
- 作为团队内部 AI 研发助手的统一入口

### Dependencies for Grape Hosting

- 一个模型服务密钥 `LLM_API_KEY`（OpenAI 兼容端点）：可以是 OpenAI / Anthropic / DeepSeek 等厂商直连，也可以是自建网关（如 `https://<你的网关>/v1`）
- 平台自动开通的持久卷，挂载到 `/app/data`

### Why Deploy Grape on Railway?

Railway 把 Grape 的服务、容器启动引导、公网 HTTPS 域名与持久卷打包成一次点击的部署：你不需要准备服务器、不需要配 nginx、不需要进容器改配置。填一个 `LLM_API_KEY` 后，注册、登录、创建仓库、跑第一个 Agent 任务都在浏览器里完成，同时保留对环境变量、实时日志、指标和扩缩容的完全控制。

### 部署后要做的三件事

1. 打开域名，用**用户名 + 密码注册**（注册成功即登录）
2. 进 `/admin`，用 `GRAPE_ADMIN_PASSWORD` 登录（该值在 Variables 页可查看），改掉初始密码
3. 在「Agent 配置」里确认执行引擎在线（本模板已内置 `opencode`），并选择模型

### 常见故障

| 现象 | 原因 | 处理 |
|---|---|---|
| 页面能开，提交任务提示「无可用引擎」 | 没填 `LLM_API_KEY` | 在 Variables 里补 `LLM_API_KEY`（可选 `LLM_BASE_URL` / `LLM_MODEL`），保存后自动重部署 |
| 任务失败，日志里是鉴权 / 404 | key 与端点不匹配 | 检查 `LLM_BASE_URL` 是否带 `/v1`，`LLM_MODEL` 前缀是否与 `LLM_PROVIDER_ID`（默认 `custom`）一致 |
| `server_base_url` 指向 `localhost:3000` | 域名在容器启动后才生成 | 点一次 `Redeploy`；或显式设置 `SERVER_BASE_URL=https://<你的域名>` |
| OAuth 登录回跳失败 | 回调地址未登记 | 若要 GitCode / GitHub 登录，把 `https://<你的域名>/api/auth/callback/{gitcode,github}` 登记到对应 OAuth App |
| 重启后登录态丢失 / 数据没了 | 卷未挂载或挂错路径 | 确认卷挂载路径为 `/app/data` |

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
