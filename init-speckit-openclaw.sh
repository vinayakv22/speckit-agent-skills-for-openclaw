#!/usr/bin/env bash

# Init SpecKit for OpenClaw 🦅
# This script automates the setup of the SpecKit engineering workflow for OpenClaw agents.
# It dynamically fetches templates from the official github/spec-kit repository.

set -e

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Initializing SpecKit for OpenClaw...${NC}"

# 0. Prerequisite Checks
echo -e "Checking prerequisites..."

# Function to find a valid Python 3
find_python3() {
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        if python --version 2>&1 | grep -q "Python 3"; then
            echo "python"
        fi
    fi
}

PYTHON_BIN=$(find_python3)

if [ -z "$PYTHON_BIN" ]; then
    echo -e "${RED}Error: Python 3 is required but was not found in your PATH.${NC}"
    echo -e "Please install Python 3:"
    echo -e "  - macOS: brew install python"
    echo -e "  - Debian/Ubuntu: sudo apt-get install python3"
    echo -e "  - Fedora: sudo dnf install python3"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}Error: 'curl' is required but was not found.${NC}"
    echo -e "Please install it using your package manager:"
    echo -e "  - macOS: brew install curl"
    echo -e "  - Debian/Ubuntu: sudo apt-get install curl"
    echo -e "  - Fedora: sudo dnf install curl"
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo -e "${RED}Error: 'unzip' is required but was not found.${NC}"
    echo -e "Please install it using your package manager:"
    echo -e "  - macOS: brew install unzip"
    echo -e "  - Debian/Ubuntu: sudo apt-get install unzip"
    echo -e "  - Fedora: sudo dnf install unzip"
    exit 1
fi

echo -e "Using $PYTHON_BIN for transformation..."

# Target directories
SKILLS_DIR=".openclaw/skills"
SPECIFY_DIR=".specify"

# 1. Fetch latest version tag from GitHub API
echo -e "Fetching latest release version from GitHub..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/github/spec-kit/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Failed to fetch latest version tag.${NC}"
    exit 1
fi
echo -e "Latest version: ${GREEN}$LATEST_VERSION${NC}"

# 2. Construct download URL
DOWNLOAD_URL="https://github.com/github/spec-kit/releases/download/${LATEST_VERSION}/spec-kit-template-claude-sh-${LATEST_VERSION}.zip"
TEMP_ZIP="/tmp/speckit-release-$$.zip"
TEMP_EXTRACT="/tmp/speckit-extract-$$"

# 3. Download and extract to temporary location
echo -e "${YELLOW}Downloading SpecKit templates...${NC}"
if ! curl -L -o "$TEMP_ZIP" "$DOWNLOAD_URL"; then
    echo -e "${RED}Error: Failed to download SpecKit templates.${NC}"
    exit 1
fi

echo -e "Extracting templates to temporary directory..."
mkdir -p "$TEMP_EXTRACT"
unzip -o -q "$TEMP_ZIP" -d "$TEMP_EXTRACT"

# 4. Create necessary local directories
mkdir -p "$SKILLS_DIR"
mkdir -p "$SPECIFY_DIR/memory"
mkdir -p "$SPECIFY_DIR/templates"
mkdir -p "$SPECIFY_DIR/scripts/bash"

# 5. Populate project with official templates (excluding .claude)
echo -e "Populating project with templates and scripts..."
cp -r "$TEMP_EXTRACT/.specify/templates/"* "$SPECIFY_DIR/templates/"
cp -r "$TEMP_EXTRACT/.specify/scripts/bash/"* "$SPECIFY_DIR/scripts/bash/"

# 6. Generate OpenClaw skills using the inline transformer
echo -e "${YELLOW}Generating native OpenClaw skills...${NC}"
TEMP_PYTHON_SCRIPT="/tmp/transform-$$.py"
COMMANDS_SRC="$TEMP_EXTRACT/.claude/commands"

cat << 'EOF' > "$TEMP_PYTHON_SCRIPT"
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
    return "\n".join(new_lines)

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
        frontmatter = f"---\nname: {skill_name}\ndescription: {description}\ncompatibility: Requires spec-kit project structure with .specify/ directory\nmetadata:\n  author: github-spec-kit\n  source: templates/commands/{cmd_name}.md\n---"
        skill_content = f"{frontmatter}\n\n# Speckit {cmd_name.title()} Skill\n\n{transformed_body}\n"
        (skill_path / "SKILL.md").write_text(skill_content, encoding="utf-8")
        print(f"Generated skill: {skill_name}")

if __name__ == "__main__":
    main()
EOF

python3 "$TEMP_PYTHON_SCRIPT" "$COMMANDS_SRC"

# 8. Self-deletion
# If the script is run as a file (not piped) and we're not in the source repo, delete it.
if [ -f "$0" ] && [ ! -f "scripts/transform-commands-to-skills.py" ]; then
    rm -f "$0"
fi

echo -e ""
echo -e "${GREEN}✓ SpecKit workflow initialized successfully!${NC}"
echo -e "${CYAN}Local Skills created in: $SKILLS_DIR${NC}"
echo -e "${CYAN}Templates created in: $SPECIFY_DIR/templates${NC}"
echo -e "${YELLOW}Note: No temporary directories or scripts were left in the project root.${NC}"
echo -e ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Open your OpenClaw agent."
echo -e "2. Activate the ${CYAN}speckit-workflow${NC} skill from ClawHub."
echo -e "3. Follow the orchestrator's guidance to start your project."
