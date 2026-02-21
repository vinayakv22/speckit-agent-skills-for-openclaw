# SpecKit for OpenClaw 🦅

### *The Professional Engineering Lifecycle for your Agent.*

**SpecKit for OpenClaw** is a master orchestrator that brings the power of Spec-Driven Development (SDD) to the OpenClaw ecosystem. It transforms your agent from a simple chat interface into a structured engineering partner that can autonomously navigate complex software projects.

---

## 🤖 How it Works

The `speckit-workflow` skill acts as the "brain" for your **OpenClaw agent**. Once activated, it directs the agent to follow a rigorous, industry-standard engineering lifecycle. Instead of jumping straight into code, the agent is guided to:

1.  📜 **Constitution**: Establish project principles, code quality standards, and architectural constraints.
2.  📝 **Specify**: Transform high-level requirements into formal, technical `spec.md` files.
3.  🔍 **Clarify**: Proactively identify and resolve ambiguities through structured questioning.
4.  🏗️ **Plan**: Derive detailed technical architecture and step-by-step implementation plans.
5.  📋 **Tasks**: Break the plan into atomic, dependency-aware micro-tasks.
6.  👷 **Implement**: Execute code changes in isolated, focused sessions with dynamic task grouping and atomic commits.

---

## 🏗️ Advanced Orchestration

This skill is designed for maximum agent autonomy and reliability:

- **Workflow State Awareness**: The agent automatically detects current progress by checking for existing artifacts (`constitution.md`, `spec.md`, etc.), allowing it to resume seamlessly from where it left off.
- **Sub-Agent Delegation**: The master skill directs the main agent to spawn or delegate tasks to specialized sub-agents for each phase, maintaining clean context boundaries.
- **Session Isolation**: It instructs the agent to use fresh sessions for implementation, preventing context bloat and ensuring high-precision code output.
- **Atomic Commits & Pushes**: The agent is directed to commit and push changes after every successfully completed task chunk, ensuring a clean and recoverable project history.

---

## ⚙️ Project Setup

Before the agent can utilize these specialized workflows, the project must be initialized to include the necessary local skills and templates. Run the appropriate command in your **terminal within the project's root directory**:

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/vinayak/speckit-agent-skills-for-openclaw/main/init-speckit-openclaw.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vinayak/speckit-agent-skills-for-openclaw/main/init-speckit-openclaw.ps1" -OutFile "init.ps1"; .\init.ps1
```

This sets up the `.openclaw/skills/` and `.specify/` directories that the agent will interact with during the workflow.

---

## 📂 Requirements

- **OpenClaw Agent**
- **Python 3**, **curl**, and **unzip** (The `init` script will guide you if these are missing).

---

*Powered by [github/spec-kit](https://github.com/github/spec-kit). Optimized for OpenClaw.*
