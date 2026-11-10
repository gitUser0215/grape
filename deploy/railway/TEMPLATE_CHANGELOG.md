# Grape Railway 模板 · CHANGELOG

> 用途：模板用户会收到「有更新可用」的通知，但他们**不知道值不值得升级**。每次合并到默认分支前，先把这一版改了什么、要不要动手，写在这里（官方 best practices 明确要求）。

## 更新分两类，机制不同

| 类型 | 你做什么 | 用户会怎样 |
|---|---|---|
| **只改代码**（业务代码 / `Dockerfile.railway` / `docker-entrypoint.sh`） | 合入默认分支 `main`，无需重新发布模板 | Railway 自动检测 → 用户收到更新通知 → 他点 Apply 后会**用新 commit 重新构建** |
| **改编排**（新增/修改变量、卷路径、端口、服务结构、模板页正文） | 必须在 Composer 里改完**重新 Publish** | 已部署用户不会自动变，需要按本文件说明手动补；新部署直接拿到新版 |

> ⚠️ 若模板改为「预构建镜像源」（Docker Image），**不再有自动更新通知**（官方限制）；那时必须用不可变 tag（如 `v0.3.0`）并在本文件记录当前 tag。

---

## 模板模板（复制这段填每一版）

```
## vX.Y.Z — YYYY-MM-DD

- 影响面：仅代码 / 含编排变化
- 变更：
  - 这里写一条一句
- 升级动作：无需操作 / 需要在 Variables 补 xxx / 需要改卷路径为 xxx
- 破坏性变更：无 / 说明（必须写清楚为什么、怎么迁移）
- 回滚方式：重新部署上一个 commit / 修改变量 xxx 回旧值
```

---

## v0.1.0 — 2026-11-10

- 影响面：**首次发布**（仅代码，模板编排随首次发布）
- 变更：
  - 新增 `Dockerfile.railway`：在原有 Python 镜像上加 Node 22 + `opencode-ai`，引擎家目录指向持久卷 `/app/data/engine-home`
  - 新增 `docker-entrypoint.sh`：启动时自动补齐三件事 —— `JWT_SECRET`（为空则生成并落卷）、对外基址（`SERVER_BASE_URL` > `RAILWAY_PUBLIC_DOMAIN`）、引擎模型配置（按 `LLM_*` 生成 `opencode.json`）
  - 新增 `railway.json`：指定 `dockerfilePath=Dockerfile.railway`、健康检查 `/api/health`（300 s）、失败重启
- 升级动作：无（首次发布）
- 破坏性变更：无。现有 `Dockerfile` / `docker-compose.yml` / 业务代码均未改动
- 回滚方式：删除对应 commit 后重新部署
