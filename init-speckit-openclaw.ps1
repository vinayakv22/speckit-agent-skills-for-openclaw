# Init SpecKit for OpenClaw 🦞
# This script automates the setup of the SpecKit engineering workflow for OpenClaw agents on Windows.
# It dynamically fetches templates from the official github/spec-kit repository.

$ErrorActionPreference = "Stop"

# 0. Prerequisite Checks
Write-Host "Initializing SpecKit for OpenClaw..." -ForegroundColor Cyan
Write-Host "Checking prerequisites..."

function Find-Python3 {
    if (Get-Command "python3" -ErrorAction SilentlyContinue) {
        return "python3"
    }
    elseif (Get-Command "python" -ErrorAction SilentlyContinue) {
        $version = python --version 2>&1
        if ($version -match "Python 3") {
            return "python"
        }
    }
    return $null
}

$PYTHON_BIN = Find-Python3

if (-not $PYTHON_BIN) {
    Write-Host "Error: Python 3 is required but was not found in your PATH." -ForegroundColor Red
    Write-Host "Please install Python 3 from https://www.python.org/downloads/windows/"
    exit 1
}

Write-Host "Using $PYTHON_BIN for transformation..."

# Target directories
$SKILLS_DIR = ".openclaw/skills"
$SPECIFY_DIR = ".specify"

# 1. Fetch latest version tag from GitHub API
Write-Host "Fetching latest release version from GitHub..." -ForegroundColor Yellow
$githubApiUrl = "https://api.github.com/repos/github/spec-kit/releases/latest"
try {
    $response = Invoke-RestMethod -Uri $githubApiUrl -Method Get
    $LATEST_VERSION = $response.tag_name
} catch {
    Write-Host "Error: Failed to fetch latest version tag from GitHub API." -ForegroundColor Red
    exit 1
}

if (-not $LATEST_VERSION) {
    Write-Host "Error: Failed to fetch latest version tag." -ForegroundColor Red
    exit 1
}
Write-Host "Latest version: $LATEST_VERSION" -ForegroundColor Green

# 2. Construct download URL
$DOWNLOAD_URL = "https://github.com/github/spec-kit/releases/download/$LATEST_VERSION/spec-kit-template-claude-ps-$LATEST_VERSION.zip"
$TEMP_DIR = [System.IO.Path]::GetTempPath()
$RANDOM_ID = Get-Random
$TEMP_ZIP = Join-Path $TEMP_DIR "speckit-release-$RANDOM_ID.zip"
$TEMP_EXTRACT = Join-Path $TEMP_DIR "speckit-extract-$RANDOM_ID"

# 3. Download and extract to temporary location
Write-Host "Downloading SpecKit templates..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TEMP_ZIP
} catch {
    Write-Host "Error: Failed to download SpecKit templates." -ForegroundColor Red
    exit 1
}

Write-Host "Extracting templates to temporary directory..."
if (Test-Path $TEMP_EXTRACT) { Remove-Item -Recurse -Force $TEMP_EXTRACT }
New-Item -ItemType Directory -Path $TEMP_EXTRACT | Out-Null
Expand-Archive -Path $TEMP_ZIP -DestinationPath $TEMP_EXTRACT -Force

# 4. Create necessary local directories
New-Item -ItemType Directory -Path $SKILLS_DIR -Force | Out-Null
New-Item -ItemType Directory -Path "$SPECIFY_DIR/memory" -Force | Out-Null
New-Item -ItemType Directory -Path "$SPECIFY_DIR/templates" -Force | Out-Null
New-Item -ItemType Directory -Path "$SPECIFY_DIR/scripts/bash" -Force | Out-Null

# 5. Populate project with official templates
Write-Host "Populating project with templates and scripts..."
Copy-Item -Path "$TEMP_EXTRACT/.specify/templates/*" -Destination "$SPECIFY_DIR/templates/" -Recurse -Force
Copy-Item -Path "$TEMP_EXTRACT/.specify/scripts/bash/*" -Destination "$SPECIFY_DIR/scripts/bash/" -Recurse -Force

# 6. Generate OpenClaw skills using the inline transformer
Write-Host "Generating native OpenClaw skills..." -ForegroundColor Yellow
$TEMP_PYTHON_SCRIPT = Join-Path $TEMP_DIR "transform-$RANDOM_ID.py"
$COMMANDS_SRC = Join-Path $TEMP_EXTRACT ".claude/commands"

$pythonScriptContent = @"
import os
import sys
import re
from pathlib import Path

SKILL_DESCRIPTIONS = {
    "analyze": "Comprehensive cross-artifact consistency & alignment report for Spec-kit projects.",
    "checklist": "Generate quality checklists to validate requirements completeness, clarity, and consistency.",
    "clarify": "Structured question generation to de-risk ambiguous areas before implementation planning.",
    "constitution": "Establish and manage the project's governing principles and development guidelines.",
    "implement": "Execute implementation phases based on an approved technical plan.",
    "plan": "Generate technical implementation plans from feature specifications.",
    "specify": "Create or update feature specifications from natural language descriptions.",
    "tasks": "Break down implementation plans into actionable task lists.",
    "taskstoissues": "Convert Markdown tasks into GitHub issues or other tracking items.",
}

def transform_content(command_name, body):
    body = re.sub(r'/speckit\.([a-z]+)', r'speckit-\1', body)
    body = body.replace('## User Input', '## User Provided Context')
    body = body.replace('You **MUST** consider the user input before proceeding', 'You **MUST** consider the User Provided Context before proceeding')
    body = body.replace('$ARGUMENTS', '{{user_provided_context}}')
    if command_name == "specify":
        old_pattern = r"The text the user typed after /speckit\.specify in the triggering message is the feature description\. Assume you always have it available in this conversation even if \$ARGUMENTS appears literally below\. Do not ask the user to repeat it unless they provided an empty command\."
        new_para = "The feature description provided by the user is the primary input for this skill. Assume the context is available in {{user_provided_context}}. Do not ask the user to repeat it unless the provided context is empty."
        body = re.sub(old_pattern, new_para, body)
    lines = body.splitlines()
    new_lines = []
    for line in lines:
        if command_name == "constitution" and "Read each command file in" in line:
            new_lines.append(line)
        else:
            line = re.sub(r'\bCommand\b', 'Skill', line)
            line = re.sub(r'\bCOMMAND\b', 'SKILL', line)
            line = re.sub(r'\bcommand\b', 'skill', line)
            new_lines.append(line)
    return "
".join(new_lines)

def main():
    repo_root = Path.cwd()
    source_dir = Path(sys.argv[1]).resolve()
    target_dir = repo_root / ".openclaw" / "skills"
    target_dir.mkdir(parents=True, exist_ok=True)
    command_files = sorted(source_dir.glob("*.md"))
    for cmd_file in command_files:
        content = cmd_file.read_text(encoding="utf-8")
        if content.startswith("---"):
            parts = content.split("---", 2)
            body = parts[2].strip() if len(parts) >= 3 else content
        else:
            body = content
        cmd_name = cmd_file.stem
        if cmd_name.startswith("speckit."):
            cmd_name = cmd_name[len("speckit."):]
        skill_name = f"speckit-{cmd_name}"
        skill_path = target_dir / skill_name
        skill_path.mkdir(parents=True, exist_ok=True)
        transformed_body = transform_content(cmd_name, body)
        description = SKILL_DESCRIPTIONS.get(cmd_name, f"Spec-kit workflow skill: {cmd_name}")
        frontmatter = f"---
name: {skill_name}
description: {description}
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: templates/commands/{cmd_name}.md
---"
        skill_content = f"{frontmatter}

# Speckit {cmd_name.title()} Skill

{transformed_body}
"
        (skill_path / "SKILL.md").write_text(skill_content, encoding="utf-8")
        print(f"Generated skill: {skill_name}")

if __name__ == "__main__":
    main()
"@

$pythonScriptContent | Out-File -FilePath $TEMP_PYTHON_SCRIPT -Encoding utf8
& $PYTHON_BIN $TEMP_PYTHON_SCRIPT $COMMANDS_SRC

# 7. Cleanup
Remove-Item $TEMP_ZIP -Force
Remove-Item $TEMP_EXTRACT -Recurse -Force
Remove-Item $TEMP_PYTHON_SCRIPT -Force

# 8. Self-deletion (only if not in our own repo)
if (-not (Test-Path "scripts/transform-commands-to-skills.py")) {
    Remove-Item $MyInvocation.MyCommand.Path -Force
}

Write-Host "`n✓ SpecKit workflow initialized successfully!" -ForegroundColor Green
Write-Host "Local Skills created in: $SKILLS_DIR" -ForegroundColor Cyan
Write-Host "Templates created in: $SPECIFY_DIR/templates" -ForegroundColor Cyan
Write-Host "Note: No temporary directories or scripts were left in the project root." -ForegroundColor Yellow
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Open your OpenClaw agent."
Write-Host "2. Activate the speckit-workflow skill from ClawHub."
Write-Host "3. Follow the orchestrator's guidance to start your project."
