<div align="center">

  <h1><a href="https://www.grapedev.cn/" target="_blank" rel="noopener noreferrer"><picture><source media="(prefers-color-scheme: dark)" srcset="assets/grape-wordmark-dark.png"><img src="assets/grape-wordmark-light.png" alt="Grape" height="56"></picture></a></h1>

  <p>
    <strong>AI Native DevOps —— Turn Any Git Project into an AI-Driven Development Workflow with One Click</strong>
    <br>
    People set requirements and review; agents do the delivery.
  </p>
  <p>
    English / <a href="README.zh.md">中文</a>
  </p>
  <p>
    <a href="https://www.grapedev.cn/">▶ Try it live</a> ·
    <a href="#4-quick-start">Quick start</a> ·
    <a href="https://github.com/grape-dev/grape/issues">Issues</a> ·
    <a href="CONTRIBUTING.md">Contributing</a> ·
    <span title="Join link coming soon"><img src="assets/community/feishu.svg" width="16" height="16" alt="Feishu">&nbsp;Feishu</span> ·
    <span title="Join link coming soon"><img src="assets/community/wechat.svg" width="16" height="16" alt="WeChat">&nbsp;WeChat</span>
  </p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/grape-dev/grape?color=blue&style=flat-square" alt="License: MIT"></a>
    <a href="https://github.com/grape-dev/grape/tags"><img src="https://img.shields.io/github/v/tag/grape-dev/grape?label=release&labelColor=black&style=flat-square" alt="tag"></a>
    <a href="https://github.com/grape-dev/grape/issues"><img src="https://img.shields.io/github/issues/grape-dev/grape?style=flat-square" alt="Issues"></a>
    <a href="https://github.com/grape-dev/grape/commits/main"><img src="https://img.shields.io/github/last-commit/grape-dev/grape?style=flat-square" alt="Last commit"></a>
    <a href="https://github.com/grape-dev/grape/graphs/contributors"><img src="https://img.shields.io/github/contributors/grape-dev/grape?color=c4f042&labelColor=black&style=flat-square" alt="contributors"></a>
  </p>

  <p>
    <a href="https://railway.com/deploy/grape-test?referralCode=25_MLK&utm_medium=integration&utm_source=template&utm_campaign=generic"><img src="https://railway.com/button.svg" alt="Deploy on Railway"></a>
  </p>
</div>

---

## 1. What Grape is

Grape turns any Git project into an autonomous AI development team: requirements, implementation, review and deployment are handed off along a single chain of agents, and people only write requirements and review.

**In one line: turn your Git project into an AI-driven autonomous development team.**

Three design principles: **the repository is the source of truth** (requirements, decisions, review evidence and delivery records all live in the repo) · **AI is a participant in the process** (it has a role, context and artifacts, and hands over via A2A) · **experience is an asset** (every run distils experience, decisions and Q&A that later tasks recall).

<details>
<summary>Expand: the five principles and three value propositions (detailed)</summary>

| Principle | Meaning | How Grape realizes it |
| --- | --- | --- |
| **Repository as first-class citizen** | The repo is the source of truth for engineering knowledge | Context stays continuous across members, tasks and tools; personnel change does not break it |
| **End-to-end closed loop, small and lean** | Break role walls so context flows inside the loop | One repo is one journey: requirement → Coding → QA → SRE hand over in the same chain, no cross-role ticketing |
| **Context as an asset** | Decisions, follow-up questions and experience are reusable | Persisted on the repo and searchable across sessions |
| **AI is a primary participant** | A peer execution unit | Agents hold roles and artifacts, hand over via A2A, people approve at key points |
| **Experience flywheel** | Every run makes the organization smarter | Experience, decisions and Q&A are distilled and recalled into later tasks |

| # | Value proposition | Description |
| --- | --- | --- |
| 1 | **One-click AI hosting, autonomous evolution** | After connecting, the whole pipeline is driven by multi-agent handoff: issues triaged, code implemented, PRs reviewed, builds deployed |
| 2 | **No IDE needed, full R&D cycle anywhere** | Feishu or the WebUI is your development interface; everyone can contribute to delivery |
| 3 | **Open source as templates, instant trial and customization** | Community projects become templates: one-click creation, auto trial deployment, Skill-driven customization |

</details>

## 2. What Grape can do

| Capability | What you get |
| --- | --- |
| **Five-stage agent pipeline** | VOD collects voice and files issues → Issue triages and assigns → Coding implements and opens PRs → QA reviews and scans for security → SRE builds, deploys and operates; the Chat agent answers anytime. Any incoming event runs the whole chain automatically. |
| **One-click hosting for any Git project** | Pick a template or point at an existing repo → the Agent × Skill scene is applied → async onboarding analyses the project and files trial-deployment and exploration issues → from then on every issue / PR is handled automatically. |
| **Skills library** | 15+ official skills across the lifecycle (voice collection, issue management, implementation, PR review, build/deploy/ops, notifications, onboarding), plus custom skills at official / repository / personal level. |
| **Three entry points** | GitCode webhooks (issue / PR / comment / build / deploy events) · Feishu WebSocket bots (100+, isolated) · WebUI (Dashboard / Pipeline / Agent / Chat / Skills / Settings). |
| **Multi-tenant and auditable** | GitHub/GitCode OAuth sign-up, login allowlist, per-user credentials; every agent run is logged (logs, duration, verdict) and traceable in the pipeline. |
| **Pluggable engines** | opencode / codearts and more, chosen by online-healthy-installed. |

## 3. Problems it solves

In traditional DevOps everything from requirement to release is manual: people triage and label issues, write the code, review the PRs and trigger builds. The more projects, the higher the cost — and context scatters.

| Stage | Traditional workflow | Grape |
| --- | --- | --- |
| Requirement intake | Manually collect feedback | The VOD agent clusters feedback into issues |
| Issue processing | Manual triage, labels, assignment | The Issue agent classifies and assigns automatically |
| Implementation | Developers write the code | The Coding agent implements and opens PRs |
| Code review | Manual review | The QA agent reviews and scans for security |
| Build and deploy | Manual / CI triggered | The SRE agent builds, deploys and operates automatically |

Result: developers move from **executors** to **decision makers** — they define direction and review outcomes only.

## 4. Quick Start

Two install paths — pick one: hand it to an agent, or do it yourself.

<details open>
<summary><strong>① Let an agent install it (recommended)</strong></summary>

Hand the line below to your AI agent and let it handle everything:

```text
Install and start the Grape platform for me by following https://gitcode.com/workSpace-hands-on/paper/blob/main/grape/README/v4/SETUP.AGENT.md
```

Execution engine and model configuration, hosting your first repository, the preflight check and deployment are covered in **[SETUP.AGENT.md](SETUP.AGENT.md)**.

</details>

<details>
<summary><strong>② Manual installation (one command)</strong></summary>

Install and start — one command does it all:

```bash
git clone https://github.com/grape-dev/grape.git && python grape/quickstart.py
```

Windows PowerShell (5.1 does not support `&&` — use `;` instead):

```powershell
git clone https://github.com/grape-dev/grape.git ; python grape/quickstart.py
```

The first sign-in, platform-facing configuration and deployment are covered in **[SETUP.HUMAN.md](SETUP.HUMAN.md)**.

</details>

### Two required steps (self-hosting)

| Step | If skipped | How |
| --- | --- | --- |
| **Configure OAuth app credentials** | GitCode / GitHub sign-in returns 400 (`not_configured`) and the buttons stay grey | Fill `client_id` / `client_secret` for both providers in `configs/oauth-providers.json`; the callback must be `https://<domain>/api/auth/callback/{gitcode,github}` |
| **Configure the public base URL** | Falls back to `localhost:3000`; OAuth callbacks cannot reach the service and login/hosting fail | Set `server_base_url` and `webhook_url` in `configs/server-config.json` to the public address |

> On hosted platforms (e.g. the Railway template) both steps are automated: the base URL is derived from the platform domain and OAuth credentials are entered on the `/admin` page — no file edits inside the container.

## 5. Going further

- **Install and deploy**: source and container deployments — see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- **Develop and test**: run `pytest tests/`; details in [CONTRIBUTING.md](CONTRIBUTING.md)

## Community

- **Issues** — https://github.com/grape-dev/grape/issues
- <img src="assets/community/feishu.svg" width="16" height="16" alt="Feishu">&nbsp;**Feishu** — join link coming soon; once connected to Grape you can also give feedback in your bound group chat
- <img src="assets/community/wechat.svg" width="16" height="16" alt="WeChat">&nbsp;**WeChat** — join link coming soon
- **Community** — https://www.grapedev.cn/community.html

## Security

Vulnerability reporting and the security model of agent execution: [SECURITY.md](SECURITY.md).

## License

MIT — see [LICENSE](LICENSE).
