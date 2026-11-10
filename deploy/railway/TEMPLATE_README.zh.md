# Deploy & Host Grape

> 用 Agent 驱动研发流水线的平台：任务编排、技能库、仓库托管一体化。

## Deploy and Host Grape

Grape 是一个 AI 原生 DevOps 平台。它把研发流程（需求、任务、评审、发布）映射成可被 Agent 执行的任务，并把技能、模板、仓库托管统一到一个 WebUI 里。

### About Hosting Grape

本模板用仓库根目录的 `Dockerfile.railway` 构建**单个服务**，监听 **3000** 端口，自动签发 HTTPS 域名。

- **持久化存储**：卷挂载到 `/app/data`，SQLite 会话库、技能存储、执行引擎家目录、日志都在这里，重部署不丢。
- **开箱即用**：只需要填一个 `LLM_API_KEY`。`JWT_SECRET` 由模板变量函数自动生成，对外基址（`server_base_url`）由平台域名在容器启动时自动推导。
- **浏览器内完成引导**：无需 CLI。打开域名 → 用户名+密码注册（未配置邮箱时自动跳过验证码）→ 直接可用。

### Common Use Cases

- 把 Issue/PR 流转自动化成 Agent 任务
- 用统一技能库沉淀团队研发规范
- 给多个仓库挂同一套流水线与评审规则
- 作为内部 AI 研发助手的统一入口

### Dependencies for Grape Hosting

- 一个模型服务密钥（`LLM_API_KEY`，OpenAI 兼容端点）。可以是 OpenAI / Anthropic / DeepSeek 等厂商直连，也可以是自建网关（如 `https://<你的网关>/v1`）。
- 平台自动开通的持久卷（挂载到 `/app/data`）。

### 部署后要做的三件事

1. 打开域名，用**用户名 + 密码注册**（注册成功即登录）
2. 进 `/admin`，用 `GRAPE_ADMIN_PASSWORD` 登录（在 Variables 页可查看该值），改掉初始密码
3. 在「Agent 配置」里确认执行引擎在线（本模板已内置 `opencode`），并选择模型

### 常见故障

| 现象 | 原因 | 处理 |
|---|---|---|
| 页面能开，提交任务提示「无可用引擎」 | 没填 `LLM_API_KEY` | 在 Variables 里补 `LLM_API_KEY`（可选 `LLM_BASE_URL` / `LLM_MODEL`），保存后自动重部署 |
| 任务失败，日志里是鉴权/404 | key 与端点不匹配 | 检查 `LLM_BASE_URL` 是否带 `/v1`，`LLM_MODEL` 前缀是否与 `LLM_PROVIDER_ID`（默认 `custom`）一致 |
| `server_base_url` 指向 `localhost:3000` | 域名在容器启动后才生成 | 点一次 `Redeploy`；或显式设置 `SERVER_BASE_URL=https://<你的域名>` |
| OAuth 登录回跳失败 | 回调地址未登记 | 若要 GitCode/GitHub 登录，请把 `https://<你的域名>/api/auth/callback/{gitcode,github}` 登记到对应 OAuth App |
| 重启后登录态丢失/数据没了 | 卷未挂载或挂错路径 | 确认卷挂载路径为 `/app/data` |

### 容器参数（部署时会自动带上）

| 项 | 值 |
|---|---|
| 构建 | 仓库根目录 `Dockerfile.railway`（`railway.json` 指定） |
| 端口 | `3000` |
| 卷 | `/app/data` |
| 健康检查 | `/api/health`（超时 300 s，首启要拉模板库） |
| 区域 | 未固定，按部署者账号的默认区域 |

### References

- 项目主页与文档：见仓库 `README.zh.md`
- 生产部署说明：`docs/DEPLOYMENT.zh.md`
- 平台配置（OAuth / 机器人 / 引擎与模型）：`docs/CONFIGURATION.zh.md`
