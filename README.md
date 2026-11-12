<div align="center">

  <h1><a href="https://www.grapedev.cn/" target="_blank" rel="noopener noreferrer"><picture><source media="(prefers-color-scheme: dark)" srcset="assets/grape-wordmark-dark.png"><img src="assets/grape-wordmark-light.png" alt="Grape" height="56"></picture></a></h1>

  <p>
    <strong>AI Native DevOps —— Turn Any Git Project into an AI-Driven Development Workflow with One Click</strong>
    <br>
    No IDE required. Design, develop, test, and ship anywhere, anytime — everyone on your team is a shipper.
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

## 1. Principles and Value

**From process-driven work where people treat AI as a tool, to workflow-driven collaboration between AI and people** — turn any Git project into a self-evolving AI development workflow: people only create requirements and review; AI completes the journey from requirement to delivery.

| Principle / characteristic | Meaning | How Grape realizes it |
| --- | --- | --- |
| **Repository as first-class citizen** (design premise) | The repository is the source of truth for engineering knowledge: requirements, decisions, review evidence and delivery records are all held by it | Context stays continuous across members, tasks and tools, and does not break with personnel change → [Host your first repository](SETUP.AGENT.md#host-your-first-repository) |
| **End-to-end closed loop, small and lean** | Break down role walls so context flows inside the loop; small closed-loop teams shorten decision chains | One repository is one complete journey: requirement → Coding → QA → SRE hand over inside the same loop, with no cross-role ticketing → [Pipeline and handoff](docs/WORKFLOW.md#five-stage-pipeline-and-handoff) |
| **Context as an asset** | Decisions, follow-up questions and experience are visible and reusable across members, tasks and tools; organizational memory becomes explicitly manageable | Decisions, Q&A and task summaries persist on the repository and are searchable across sessions → [Where those assets live](docs/WORKFLOW.md#where-context-as-an-asset-lives) |
| **AI is a primary participant in the process** | A peer execution unit: assigned tasks, orchestrated into the delivery chain, collaborating with other agents through structured interfaces | Agents hold a role, input, context and artifact, hand over via A2A, and people approve at key points → [Execution engine and model](docs/CONFIGURATION.md#execution-engine-and-model) |
| **Experience flywheel** | Every run makes the organization smarter; the platform asynchronously distils experience, decisions and question–answer pairs | Those three asset types persist on the repository and are recalled by relevance into later tasks → [Flywheel: the three asset types](docs/WORKFLOW.md#flywheel-assets-the-three-types) |

### Value proposition

Grape redefines the software development workflow — no longer "human-driven with AI assistance", but "AI-driven, human-reviewed".

| # | Core Value | Description |
| --- | --- | --- |
| **1** | **One-Click AI Hosting, Autonomous Evolution** | Connect any Git project to Grape, and the full pipeline from requirements to delivery is driven by Multi-Agent handoff. Issues auto-triage, code auto-implemented, PRs auto-reviewed, builds auto-deployed — iteration velocity **skyrockets**. |
| **2** | **No IDE, Anywhere Full-Stack R&D** | Feishu or WebUI becomes your development interface. Design, develop, test, ship — no editor required. Everyone on the team can directly contribute to delivery. |
| **3** | **Open Source as Templates, Instant Experience & Customization** | Every open-source project in the community is your starting template. One-click creation, auto-deployment for experience, Skill-driven customization — an AI development workflow from 0 to 1, ready instantly. |

## 2. Core Features

| # | Core features | Description |
| --- | --- | --- |
| 1 | **Managed from the moment it enters the repository** | The VOD agent clusters feedback into issues; the Issue agent classifies and assigns them |
| 2 | **Agent-to-agent handoff** | The five-stage pipeline hands over via A2A — no manual routing or status synchronization → [How handoff works](docs/WORKFLOW.md#five-stage-pipeline-and-handoff) |
| 3 | **Closed verification loop** | A QA rejection returns the issue to Coding; the quality gate is enforced by the workflow |
| 4 | **Human holds the gate** | Approvals and releases at key stages are decided by a person → [Where humans decide](docs/WORKFLOW.md#where-humans-hold-the-gate) |
| 5 | **Multi-engine broadcast** | One task runs in parallel across several engines; the best artifact is selected automatically → [Engine configuration](docs/CONFIGURATION.md#execution-engine-and-model) |
| 6 | **Flywheel assets** | Decisions, Q&A and task summaries persist on the repository, recalled by later tasks → [The three asset types](docs/WORKFLOW.md#flywheel-assets-the-three-types) |
| 7 | **Full observability** | Task centre, pipeline timeline, agent status and health are inspectable |
| 8 | **IM-native collaboration** | Requirements, approvals and progress in Feishu; the Chat Agent is the entry point → [Platform-facing configuration](docs/CONFIGURATION.md) |

## 3. Problems Addressed

Grape orchestrates multiple AI agents that hand work over to one another, so the repetitive steps of the development workflow complete autonomously. Once a traditional Git project is connected, it gains a complete AI development workflow — requirement clarification, implementation, review and verification, build and deployment — AI Native end to end.

These stages complete without human execution, which leaves developers as decision-makers: define direction, review outcomes.

| Stage | Traditional workflow | Grape AI Native workflow |
| --- | --- | --- |
| Requirement collection | Manual feedback aggregation | VOD Agent gathers developer voice and clusters it |
| Issue handling | Manual triage, labelling, assignment | VOD / Issue Agent classify and assign automatically |
| Implementation | Developers code by hand | Coding Agent implements and opens a PR |
| Code review | Human review | QA Agent reviews and runs security scans |
| Build and deployment | Manual / CI trigger | SRE Agent builds, deploys and operates |

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

## Community

- **Issues** — https://github.com/grape-dev/grape/issues
- <img src="assets/community/feishu.svg" width="16" height="16" alt="Feishu">&nbsp;**Feishu** — join link coming soon; once connected to Grape you can also give feedback in your bound group chat
- <img src="assets/community/wechat.svg" width="16" height="16" alt="WeChat">&nbsp;**WeChat** — join link coming soon
- **Community** — https://www.grapedev.cn/community.html

## Security

Vulnerability reporting and the security model of agent execution: [SECURITY.md](SECURITY.md).

## License

MIT — see [LICENSE](LICENSE).
