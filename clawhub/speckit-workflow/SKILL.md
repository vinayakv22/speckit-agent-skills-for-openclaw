---
name: speckit-workflow
description: Complete Spec-Driven Development (SDD) orchestrator for OpenClaw. Initializes SpecKit and manages the full engineering lifecycle.
compatibility: Requires OpenClaw and a project repository
metadata:
  author: vinayak
  source: custom/speckit-workflow
---

# Speckit Workflow Skill 🦞

This is the master orchestrator for the **SpecKit for OpenClaw** engineering workflow. It is designed to be the entry point for users on ClawHub.

## 🚀 Step 1: Initialization

If this project has not been initialized with SpecKit yet, you **MUST** run the initialization script in the **root directory of your project**:

**macOS / Linux:**
```bash
curl -fsSL https://github.com/vinayakv22/speckit-agent-skills-for-openclaw/releases/latest/download/init-speckit-openclaw.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/vinayakv22/speckit-agent-skills-for-openclaw/releases/latest/download/init-speckit-openclaw.ps1" -OutFile "init.ps1"; .\init.ps1
```

**What this does**:
- Creates the `.openclaw/skills/` directory.
- Populates it with 9 specialized engineering skills (analyze, checklist, clarify, constitution, implement, plan, specify, tasks, taskstoissues).
- Sets up the `.specify/` project memory structure.

---

## 🔄 Resuming Workflow

Before starting or when returning to a project, you **MUST** determine the current state by checking for the existence of SpecKit artifacts:

1.  **Check for Initialization**: Verify if `.openclaw/skills/` and `.specify/` exist.
2.  **Determine Current Phase**:
    - If `.specify/memory/constitution.md` exists -> **Constitution** complete.
    - If `specs/<feature>/spec.md` exists -> **Specify** complete.
    - If `specs/<feature>/plan.md` exists -> **Plan** complete.
    - If `specs/<feature>/tasks.md` exists -> **Tasks** complete.
    - If tasks in `tasks.md` are partially marked `[X]` -> **Implementation** in progress.

Always resume from the first incomplete phase in the [Execution Order](#the-execution-order).

---

## 🏗️ Step 2: Workflow Orchestration

Once initialized, you **MUST** follow the canonical Spec-kit order by delegating to sub-agents.

### When to Create a Sub-Agent:
For **each phase** below, you should create or delegate to a specialized sub-agent that uses the corresponding skill found in `.openclaw/skills/`.

### The Execution Order:

1.  📜 **Constitution**: Delegate to `speckit-constitution`. Establish code quality, testing standards, and architectural constraints.
2.  📝 **Specify**: Delegate to `speckit-specify`. Transform requirements into a formal `spec.md`.
3.  🔍 **Clarify** (Optional): Delegate to `speckit-clarify` if the specification is ambiguous.
4.  🏗️ **Plan**: Delegate to `speckit-plan`. Derive technical design and implementation architecture.
5.  📋 **Tasks**: Delegate to `speckit-tasks`. Break the plan into actionable micro-tasks.
6.  ⚖️ **Analyze** (Optional): Delegate to `speckit-analyze` for cross-artifact consistency.
7.  👷 **Implement**: Delegate to `speckit-implement`.

---

## 👷 Implementation Session Management

When executing the **`speckit-implement`** phase, you **MUST**:

- **Isolate Context**: Trigger a **new agent session** for implementation to ensure focus.
- **Dynamic Task Chunking**: Group tasks from `tasks.md` dynamically based on requirements and complexity.
    - If tasks are small/simple, group 3-5 tasks (e.g., T001 to T005).
    - If tasks are complex, group 1-2 tasks.
- **Sub-Agent Execution**: For each chunk, delegate to a sub-agent using `speckit-implement`.
- **Commit & Push**: After each successfully completed chunk, the sub-agent **MUST** commit and push the changes to the repository.
- **Mark Completion**: Ensure the sub-agent marks tasks as complete `[X]` in `tasks.md` before returning.
- **Avoid Over-grouping**: Do not group too many tasks in a single sub-agent session to maintain precision and manageable diffs.

---

## User Provided Context

```text
{{user_provided_context}}
```

Use this context to start or resume the workflow. If the project is not yet initialized, begin with **Step 1: Initialization**.
