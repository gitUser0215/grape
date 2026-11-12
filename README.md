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
    <a href="#5-quick-start">Quick start</a> ·
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

> **Three design principles**
>
> - **The repository is the source of truth** — requirements, decisions, review evidence and delivery records all live in the repo, so context survives personnel changes
> - **AI is a participant in the process** — agents hold roles, context and artifacts, hand over via A2A, and people approve at key points
> - **Experience is an asset** — every run distils experience, decisions and Q&A, recalled by later tasks

## 2. What Grape can do

| Capability | What you get |
| --- | --- |
| **Five-stage agent pipeline** | VOD collects voice and files issues → Issue triages and assigns → Coding implements and opens PRs → QA reviews and scans for security → SRE builds, deploys and operates; the Chat agent answers anytime. Any incoming event runs the whole chain automatically. |
| **One-click hosting for any Git project** | Pick a template or point at an existing repo → the Agent × Skill scene is applied → async onboarding analyses the project and files trial-deployment and exploration issues → from then on every issue / PR is handled automatically. |
| **Skills library** | 15+ official skills across the lifecycle (voice collection, issue management, implementation, PR review, build/deploy/ops, notifications, onboarding), plus custom skills at official / repository / personal level. |
| **Multi-tenant and auditable** | GitHub/GitCode OAuth sign-up, login allowlist, per-user credentials; every agent run is logged (logs, duration, verdict) and traceable in the pipeline. |
| **Pluggable engines** | opencode / codearts and more, chosen by online-healthy-installed. |

## 3. The Problem

Traditional DevOps relies heavily on manual effort across the pipeline: Issues need manual triage, code needs developers to write, PRs need human review, builds and deployments need manual triggers. More projects, more overhead.

Grape's goal is to **AI-ify every one of these steps**, turning developers from executors into decision-makers — you define the direction, AI handles the rest.

| Stage | Traditional | Grape AI Native |
|-------|-----------|-----------------|
| Issue Triage | Manual classification & assignment | VOD / Issue Agent auto-classify & assign |
| Implementation | Developer writes code | Coding Agent auto-implements & submits PR |
| Code Review | Human review | QA Agent auto-review & security scan |
| Build & Deploy | Manual / CI trigger | SRE Agent auto-build, deploy, monitor |
| Requirements | Manual feedback collection | VOD Agent gathers developer voice, clusters insights |

## 4. AI Native Efficiency, Measured in Production

Data from the production database `grape_system_db`, 70-day window (as of 2026-11).

<p align="center">
  <img src="assets/metrics/en/kpi.svg" alt="8,037 issues carried · 49,968 agent tasks · 90.3% completion · 6.2 tasks per issue · 110 real users · 352 connected repos">
</p>

<p align="center">
  <img src="assets/metrics/en/monthly.svg" alt="Monthly agent tasks: 683, 5,989, 27,937, 15,360">
</p>

- **Iteration speed**: task volume nearly 10x in 70 days; 3,072 tasks/day in the last 5 days vs 901 in the previous full month
- **Issue closure**: 1,821 completed, 3.5x the previous period; 1,733 awaiting review (32.3% of in-flight) is the current bottleneck
- **Verification is the heaviest load**: qa accounts for 33% — review tasks now outnumber generation tasks

<p align="center">
  <img src="assets/metrics/en/status.svg" alt="Issue states: processing 3,022 / completed 1,821 / pending_review 1,733; task states: completed 45,111 (90.3%), failed 3,887">
</p>

<p align="center">
  <img src="assets/metrics/en/pipeline.svg" alt="Agent types: qa 16,545 / vod 13,019 / issue 11,073 / coding 6,217 / sre 2,918; event sources: A2A 18,317 = 39%">
</p>

- **Agents dispatch work to agents**: A2A is 39% of all event entries, 48% in the last five days
- **We are our own number-one user**: five grape-dev repos ran 15,055 tasks (30% of the platform); 800K lines of code, 8,386 test cases and 378 skills were produced on the pipeline

> Method: the single-day peak of 8,822 includes a ~5,000-task batch QA scan; excluding it the regular peak is 4,614. Full analysis: [AI Native practice write-up](https://gitcode.com/workSpace-hands-on/paper/blob/main/grape/%E6%B4%9E%E5%AF%9F%E5%88%86%E6%9E%90/grape-ai-native-practice-1105.html).

## 5. Quick Start

Two install paths — pick one: hand it to an agent, or do it yourself.

<details open>
<summary><strong>① Let an agent install it (recommended)</strong></summary>

Hand the line below to your AI agent and let it handle everything:

```text
Install and start the Grape platform for me by following https://github.com/gitUser0215/grape/blob/main/SETUP.AGENT.md
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

## Community

- **Issues** — https://github.com/grape-dev/grape/issues
- <img src="assets/community/feishu.svg" width="16" height="16" alt="Feishu">&nbsp;**Feishu** — join link coming soon; once connected to Grape you can also give feedback in your bound group chat
- <img src="assets/community/wechat.svg" width="16" height="16" alt="WeChat">&nbsp;**WeChat** — join link coming soon
- **Community** — https://www.grapedev.cn/community.html

## Security

Vulnerability reporting and the security model of agent execution: [SECURITY.md](SECURITY.md).

## License

MIT — see [LICENSE](LICENSE).
