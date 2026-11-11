# 托管平台部署材料（deploy/hosted）

本目录存放「托管平台一键部署」相关的全部构建与上架材料，**目录名与文件名均不含任何厂商名**，
以便同一套材料用于任意容器托管平台（只要平台能从 Dockerfile 构建、能注入域名变量、能挂持久卷）。

| 文件 | 用途 |
|---|---|
| `Dockerfile` | 平台侧构建用镜像定义：Python 运行时 + 执行引擎（`opencode`）+ 烘入项目模板 |
| `entrypoint.sh` | 容器启动引导（幂等）：补齐会话密钥、推导对外基址、同步资源、生成引擎模型配置 |
| `listing.md` | 平台上架文案（English only；概览正文，含 model endpoint、引擎、升级策略） |
| `variables.md` | 变量表：哪些必填、哪些隐形预置、哪些由平台注入 |
| `changelog.md` | 变更记录（平台用户升级前必读） |
| `icon.png` | 平台市场图标 |

## 平台侧还需要一个配置文件

仓库根目录的 `railway.json` 是**该平台强制的固定文件名**（config-as-code，只从仓库根读取），
它只做一件事：把构建入口指向本目录的 `Dockerfile`。换成其它平台时，删掉它、按对应平台的约定
重新写一份即可，本目录内容无需改动。

## 对外基址（域名）解析顺序

1. `SERVER_BASE_URL`（显式指定，优先级最高）
2. `PUBLIC_DOMAIN`（通用变量，任何平台都可注入）
3. `RAILWAY_PUBLIC_DOMAIN`（该平台自动注入）

三者都没有时只打印告警、不阻断启动（应用可用，但 OAuth 回调会指向 localhost）。

## 自建部署

与托管平台无关。自建请用仓库根的 `Dockerfile` / `docker-compose.yml`，
说明见 `docs/DEPLOYMENT.zh.md`。
