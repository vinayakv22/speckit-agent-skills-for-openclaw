#!/usr/bin/env python3
import os
import sys
import re
from pathlib import Path

# Mapping of command names to enhanced descriptions
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
    # 1. Replace "/speckit.analyze" with "speckit-analyze" (and others)
    body = re.sub(r'/speckit\.([a-z]+)', r'speckit-\1', body)
    
    # 2. Handle $ARGUMENTS replacement
    body = body.replace('## User Input', '## User Provided Context')
    body = body.replace('You **MUST** consider the user input before proceeding', 'You **MUST** consider the User Provided Context before proceeding')
    body = body.replace('$ARGUMENTS', '{{user_provided_context}}')
    
    # 3. Replace "command" with "skill" (with exceptions)
    if command_name == "specify":
        # First paragraph rephrasing for specify
        old_pattern = r"The text the user typed after /speckit\.specify in the triggering message is the feature description\. Assume you always have it available in this conversation even if \$ARGUMENTS appears literally below\. Do not ask the user to repeat it unless they provided an empty command\."
        new_para = "The feature description provided by the user is the primary input for this skill. Assume the context is available in {{user_provided_context}}. Do not ask the user to repeat it unless the provided context is empty."
        body = re.sub(old_pattern, new_para, body)

    # Perform "command" -> "skill" replacement except for the constitution line
    lines = body.splitlines()
    new_lines = []
    for line in lines:
        if command_name == "constitution" and "Read each command file in" in line:
            new_lines.append(line)
        else:
            # Replace 'command' with 'skill' (case-sensitive)
            line = re.sub(r'\bCommand\b', 'Skill', line)
            line = re.sub(r'\bCOMMAND\b', 'SKILL', line)
            line = re.sub(r'\bcommand\b', 'skill', line)
            new_lines.append(line)
    
    body = "\n".join(new_lines)

    return body

def main():
    repo_root = Path.cwd()
    
    # Allow source directory to be passed as an argument
    if len(sys.argv) > 1:
        source_dir = Path(sys.argv[1]).resolve()
    else:
        source_dir = repo_root / ".claude" / "commands"
        
    target_dir = repo_root / ".openclaw" / "skills"
    
    if not source_dir.exists():
        print(f"Error: Source directory {source_dir} not found.")
        sys.exit(1)
        
    target_dir.mkdir(parents=True, exist_ok=True)
    
    command_files = sorted(source_dir.glob("*.md"))
    
    for cmd_file in command_files:
        content = cmd_file.read_text(encoding="utf-8")
        
        # Parse YAML frontmatter
        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 3:
                body = parts[2].strip()
            else:
                body = content
        else:
            body = content
            
        cmd_name = cmd_file.stem
        if cmd_name.startswith("speckit."):
            cmd_name = cmd_name[len("speckit."):]
            
        skill_name = f"speckit-{cmd_name}"
        skill_path = target_dir / skill_name
        skill_path.mkdir(parents=True, exist_ok=True)
        
        # Transform content
        transformed_body = transform_content(cmd_name, body)
        
        # Build SKILL.md
        description = SKILL_DESCRIPTIONS.get(cmd_name, f"Spec-kit workflow skill: {cmd_name}")
        
        frontmatter = f"""---
name: {skill_name}
description: {description}
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: templates/commands/{cmd_name}.md
---"""

        skill_content = f"{frontmatter}\n\n# Speckit {cmd_name.title()} Skill\n\n{transformed_body}\n"
        
        (skill_path / "SKILL.md").write_text(skill_content, encoding="utf-8")
        print(f"Generated skill: {skill_name}")

if __name__ == "__main__":
    main()
