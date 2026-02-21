# SpecKit for OpenClaw 🦅

### *Elevate your OpenClaw agent with Spec-Driven Development.*

**SpecKit for OpenClaw** is a master orchestrator that brings the power of [github/spec-kit](https://github.com/github/spec-kit) to the OpenClaw agent. It provides a professional engineering framework that directs your agent to work as a senior developer.

---

## 🤖 How it Works

The master skill, **`speckit-workflow`**, acts as an orchestrator that guides your agent through a structured development lifecycle. Instead of simple task execution, this skill directs the **OpenClaw agent** to proactively:

1.  🛠️ **Initialize**: Setup the project with specialized engineering skills and templates.
2.  📜 **Architect**: Define project constitutions and quality standards.
3.  📝 **Specify**: Formalize feature requests into rigorous specifications.
4.  🏗️ **Plan**: Design technical architectures and step-by-step implementation plans.
5.  👷 **Implement**: Execute code with dynamic task chunking and atomic commits.

---

## 🏗️ The Engineering Pipeline

The system works through a hierarchy of delegation:

- **The Master Orchestrator**: The `speckit-workflow` skill directs the main agent to oversee the entire lifecycle.
- **Sub-Agent Delegation**: For each phase, the master skill directs the agent to spawn or delegate tasks to specialized sub-agents.
- **Local Native Skills**: These sub-agents utilize 9 specialized skills (analyze, checklist, clarify, constitution, implement, plan, specify, tasks, taskstoissues) that are generated natively within your project.

---

## ⚙️ Project Setup

The master orchestrator is **found on ClawHub** as the `speckit-workflow` skill. Once activated, the OpenClaw agent will guide you through the initialization of your project, ensuring all necessary local skills and templates are correctly configured.

Alternatively, you can manually initialize your project by running the following command in your **project's root directory**:

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/vinayak/speckit-agent-skills-for-openclaw/main/init-speckit-openclaw.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vinayak/speckit-agent-skills-for-openclaw/main/init-speckit-openclaw.ps1" -OutFile "init.ps1"; .\init.ps1
```

---

## 📂 Features

- **Workflow State Awareness**: The agent can resume work by detecting existing artifacts like `spec.md` or `plan.md`.
- **Sub-Agent Delegation**: For each phase, the master skill directs the agent to spawn or delegate tasks to specialized sub-agents.
- **Dynamic Task Chunking**: Groups implementation tasks logically based on complexity for more reliable output.
- **Atomic Commits & Pushes**: The agent is instructed to maintain a clean history by committing and pushing after each successful task chunk.
- **Session Isolation**: Implementation is done in fresh sessions to prevent context window saturation.

---

## 📜 License

Adapted from [github/spec-kit](https://github.com/github/spec-kit). Distributed under the MIT License.

*Crafted for the OpenClaw Community.*
