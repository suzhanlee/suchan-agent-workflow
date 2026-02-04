# PLAN: Open Source Lesson Learn Workflow

## Context

### Original Request
Create an automated workflow to study open-source projects and generate lesson learn documents using the AskYourQuestions methodology.

### Interview Summary

| Decision | Value | Notes |
|----------|-------|-------|
| Focus Areas | Architecture & Patterns | Initial focus; expandable later |
| Workflow Style | Question-Driven | Exploratory learning vs sequential phases |
| Document Format | Markdown | Simple, readable, GitHub-friendly |
| Command Name | `/study-project` | Skill name |
| Output Location | `docs/lessons/` | Integrated with project docs |
| Hook System | Include in MVP | State persistence, session resume |

### Research Findings

#### Existing Patterns
- `atdd-init/SKILL.md:1-12` - Skill structure with YAML frontmatter
- `atdd-criteria-generator.md:1-4` - Agent structure with frontmatter
- `atdd-hook.sh:34-75` - State management pattern (`.atdd-state.json`)
- `settings.json:9-27` - Hook registration

#### Project Commands
- No special build/test commands needed (no compilation)
- Hook: `bash .claude/scripts/lesson-hook.sh`

#### Documentation
- `docs/ARCHITECTURE.md:85-149` - Orchestrator-Agent pattern
- `docs/ARCHITECTURE.md:229-269` - State management

## Work Objectives

### Concrete Deliverables
1. Skill: `.claude/skills/study-project/SKILL.md`
2. Agent 1: `.claude/agents/project-analyzer.md`
3. Agent 2: `.claude/agents/lesson-generator.md`
4. Hook: `.claude/scripts/lesson-hook.sh`
5. State tracking: `.study-state.json`
6. Lesson template: Embedded in lesson-generator agent

### Must NOT Do
- DO NOT create a rigid 5+ step sequential workflow
- DO NOT require pre-configuration before first use
- DO NOT generate massive documents without user guidance
- DO NOT deviate from existing UX patterns (skill → agent → output)
- DO NOT scan entire codebase for every question (cache project context)
- DO NOT generate lessons without source code citations
- DO NOT use ATDD's test-oriented language (Given/When/Then)
- DO NOT write to `docs/lessons/` without user confirmation

### Definition of Done
- [ ] User can run `/study-project <github-url>`
- [ ] System analyzes repo structure and identifies patterns
- [ ] User can select focus questions to explore
- [ ] System generates markdown lesson document
- [ ] Document saved to `docs/lessons/{project-name}-lessons.md`
- [ ] State persisted in `.study-state.json` for session resume
- [ ] All A-items (verification checks) pass

## Orchestrator

### Task Flow
```
User executes: /study-project <github-url>
    ↓
[TODO-1] Create Skill Definition
    ↓
[TODO-2] Create project-analyzer Agent ─┐
                                    ├──→ [TODO-4] Create lesson-hook.sh Script
[TODO-3] Create lesson-generator Agent ─┘
    ↓
[TODO-5] Register Hook in settings.json
    ↓
[TODO-6] Verify with Real Project Test
```

### Dependency Graph
```
TODO-1 (Skill)
    ↓
TODO-2 (project-analyzer) ─┐
                        ├──→ TODO-4 (hook script)
TODO-3 (lesson-generator) ─┘
    ↓
TODO-5 (settings.json registration)
    ↓
TODO-6 (verification)
```

### Parallelization
- **TODO-2 and TODO-3** can be executed in parallel (both agent file creations, no file-level dependencies)
- Sequential: TODO-1 → (TODO-2, TODO-3) → TODO-4 → TODO-5 → TODO-6

### Commit Strategy
- Single commit after all TODOs complete
- Message: `[study-project] Add open-source lesson learn workflow`
- Commit includes: skill, agents, hook, settings.json

### Error Handling
- If skill creation fails → halt, no partial state
- If agent creation fails → halt, fix task before proceeding
- If hook registration fails → user can manually add to settings.json

### Runtime Contract
- **Input**: GitHub repository URL
- **Output**: Markdown lesson document at `docs/lessons/{project-name}-lessons.md`
- **State**: `.study-state.json` tracks progress
- **Side effects**: Creates `docs/lessons/` directory if missing

## TODOs

### [x] TODO-1: Create Skill Definition

**Type**: `work`
**Required Tools**: Write, Read
**Inputs**: None
**Outputs**: `.claude/skills/study-project/SKILL.md`

**Steps**:
- [ ] Read `atdd-init/SKILL.md` as reference template
- [ ] Create skill directory: `.claude/skills/study-project/`
- [ ] Write `SKILL.md` with:
  - [ ] YAML frontmatter (name, description, allowed-tools)
  - [ ] Usage section with example
  - [ ] Question-driven workflow explanation
  - [ ] State management integration
  - [ ] Output location specification

**Must NOT do**:
- Do not use Bash tool (skill orchestrates, doesn't execute)
- Do not hardcode question list (allow agent to generate)
- Do not implement sequential phases (this is exploratory)

**References**:
- `atdd-init/SKILL.md:1-128` - Skill structure pattern

**Acceptance Criteria**:
- [ ] **Functional**: Skill file exists at `.claude/skills/study-project/SKILL.md`
- [ ] **Static**: Valid YAML frontmatter (2 `---` markers)
- [ ] **Runtime**: Skill can be invoked via `/study-project` command
- [ ] **Cleanup**: No unused imports or redundant sections

**Verify**:
```yaml
acceptance:
  - given: ["Skill file created", "User executes /study-project command"]
    when: "Command is invoked"
    then: ["Skill loads successfully", "No YAML parsing errors"]
commands:
  - run: "test -f .claude/skills/study-project/SKILL.md"
    expect: "exit 0"
  - run: "grep -c '^---' .claude/skills/study-project/SKILL.md | grep -q '^2$'"
    expect: "exit 0"
risk: LOW
```

---

### [x] TODO-2: Create project-analyzer Agent

**Type**: `work`
**Required Tools**: Task, Read, Write
**Inputs**: Project URL from skill
**Outputs**: Analysis result (structure, patterns, questions)

**Steps**:
- [ ] Read `atdd-criteria-generator.md` as reference template
- [ ] Create `.claude/agents/project-analyzer.md`
- [ ] Define agent role:
  - [ ] Analyze repository structure using web reader
  - [ ] Identify key architecture patterns
  - [ ] Extract design patterns usage
  - [ ] Generate focus questions for exploration
- [ ] Specify input format (URL + optional focus areas)
- [ ] Specify output format (structured analysis with questions)

**Must NOT do**:
- Do not scan entire codebase for each question
- Do not hallucinate patterns without evidence
- Do not use Git commands (use web reader)
- Do not modify any files (read-only analysis)

**References**:
- `atdd-criteria-generator.md:1-4` - Agent frontmatter pattern
- Gap Analysis: Must include code citations for pattern claims

**Acceptance Criteria**:
- [ ] **Functional**: Agent generates questions based on project analysis
- [ ] **Static**: Valid YAML frontmatter
- [ ] **Runtime**: Agent can be invoked and produces structured output
- [ ] **Cleanup**: No redundant prompts or examples

**Verify**:
```yaml
acceptance:
  - given: ["Agent file created", "GitHub URL provided"]
    when: "Agent analyzes project"
    then: ["Generates 3-5 relevant questions", "Includes file references"]
commands:
  - run: "test -f .claude/agents/project-analyzer.md"
    expect: "exit 0"
  - run: "grep -c '^---' .claude/agents/project-analyzer.md | grep -q '^2$'"
    expect: "exit 0"
risk: LOW
```

---

### [x] TODO-3: Create lesson-generator Agent

**Type**: `work`
**Required Tools**: Write, Read
**Inputs**: Analysis result from project-analyzer, user question selections
**Outputs**: Markdown lesson document

**Steps**:
- [ ] Create `.claude/agents/lesson-generator.md`
- [ ] Define agent role:
  - [ ] Generate structured markdown document
  - [ ] Include sections: Architecture, Patterns, Examples, Lessons
  - [ ] Incorporate code citations
  - [ ] Format as GitHub-flavored markdown
- [ ] Define lesson document template
- [ ] Specify output location: `docs/lessons/{project-name}-lessons.md`

**Must NOT do**:
- Do not write to `docs/lessons/` without user confirmation
- Do not overwrite existing lesson files without warning
- Do not generate massive documents (limit sections per question)
- Do not run Git commands (Orchestrator handles commits)

**References**:
- `atdd-criteria-generator.md:278-283` - File naming: kebab-case
- Gap Analysis: Must require code citations for each claim

**Acceptance Criteria**:
- [ ] **Functional**: Generates markdown with required sections
- [ ] **Static**: Valid YAML frontmatter
- [ ] **Runtime**: Output file created at correct location
- [ ] **Cleanup**: No template artifacts or placeholder text

**Verify**:
```yaml
acceptance:
  - given: ["Agent receives analysis", "User confirms output"]
    when: "Lesson document is generated"
    then: ["File created at docs/lessons/", "Contains all required sections"]
commands:
  - run: "test -f .claude/agents/lesson-generator.md"
    expect: "exit 0"
  - run: "grep -c '^---' .claude/agents/lesson-generator.md | grep -q '^2$'"
    expect: "exit 0"
risk: LOW
```

---

### [x] TODO-4: Create lesson-hook.sh Script

**Type**: `work`
**Required Tools**: Write, Read, Bash
**Inputs**: State from skill execution
**Outputs**: `.claude/scripts/lesson-hook.sh`, updated `.study-state.json`, console feedback

**Steps**:
- [ ] Read `atdd-hook.sh` as reference
- [ ] Create `.claude/scripts/lesson-hook.sh`
- [ ] Implement state management:
  - [ ] Create/update `.study-state.json`
  - [ ] Track: project URL, phase, questions asked, document status
  - [ ] Phase tracking: `init` → `analyzing` → `generating` → `complete`
- [ ] Implement colored logging (INFO/SUCCESS/WARNING/ERROR)
- [ ] Implement session resume capability
- [ ] Make script executable on Unix systems

**Must NOT do**:
- Do not modify `.atdd-state.json` (separate state file)
- Do not interfere with ATDD hook execution
- Do not require manual chmod on Windows (Git Bash handles it)

**References**:
- `atdd-hook.sh:34-75` - State management pattern
- `atdd-hook.sh:11-32` - Colored logging pattern

**Acceptance Criteria**:
- [ ] **Functional**: Hook updates state and provides feedback
- [ ] **Static**: Script is syntactically valid bash
- [ ] **Runtime**: Script executes without errors
- [ ] **Cleanup**: No debug logging or commented code

**Verify**:
```yaml
acceptance:
  - given: ["Skill execution completes", "Hook is triggered"]
    when: "lesson-hook.sh runs"
    then: ["State file updated", "Colored output displayed"]
commands:
  - run: "test -f .claude/scripts/lesson-hook.sh"
    expect: "exit 0"
  - run: "bash -n .claude/scripts/lesson-hook.sh"
    expect: "exit 0"
risk: MEDIUM
```

---

### [x] TODO-5: Register Hook in settings.json

**Type**: `work`
**Required Tools**: Read, Edit
**Inputs**: `.claude/scripts/lesson-hook.sh` from TODO-4
**Outputs**: Updated `.claude/settings.json`

**Steps**:
- [ ] Read current `.claude/settings.json`
- [ ] Add hook definition to `hooks` section:
  - [ ] Hook name: `lesson-stop`
  - [ ] Description: "Project study phase transition and state management"
  - [ ] Command: `bash .claude/scripts/lesson-hook.sh`
  - [ ] Trigger: `afterSkill`
- [ ] Add skill-hook mapping to `skills.study-project.hooks` section
- [ ] Preserve existing ATDD hook configuration

**Must NOT do**:
- Do not modify ATDD hook configuration
- Do not break existing skill hook registrations
- Do not create invalid JSON

**References**:
- `settings.json:9-27` - Hook registration pattern

**Acceptance Criteria**:
- [ ] **Functional**: Hook registered and triggers on skill exit
- [ ] **Static**: Valid JSON syntax
- [ ] **Runtime**: Existing ATDD workflow still works
- [ ] **Cleanup**: No duplicate hook entries

**Verify**:
```yaml
acceptance:
  - given: ["Hook script exists", "settings.json updated"]
    when: "Skill execution completes"
    then: ["Hook triggers automatically", "State file updated"]
commands:
  - run: "jq -r '.hooks | has(\"lesson-stop\")' .claude/settings.json | grep -q 'true'"
    expect: "exit 0"
  - run: "jq -r '.skills[\"study-project\"].hooks.onStop' .claude/settings.json | grep -q 'lesson-stop'"
    expect: "exit 0"
risk: MEDIUM
```

---

### [x] TODO-6: Verify with Real Project Test

**Type**: `verification`
**Required Tools**: Skill (via command), Read
**Inputs**: Completed TODO-1 through TODO-5
**Outputs**: Verification report, test lesson document

**Steps**:
- [ ] Select a small open-source project for testing (e.g., a utility library)
- [ ] Execute `/study-project <github-url>`
- [ ] Verify skill invocation works
- [ ] Verify project-analyzer produces questions
- [ ] Verify lesson-generator creates document
- [ ] Verify hook updates state
- [ ] Review generated lesson document for quality
- [ ] Verify all required sections present
- [ ] Verify code citations included
- [ ] Verify file location correct

**Must NOT do**:
- Do not run Git commands (read-only verification)
- Do not modify any generated files
- Do not execute `/study-project` with production repositories

**References**:
- Verification A-items from verification-planner

**Acceptance Criteria**:
- [ ] **Functional**: End-to-end workflow produces lesson document
- [ ] **Static**: Lesson document has valid markdown format
- [ ] **Runtime**: All phases complete without errors
- [ ] **Cleanup**: No temporary test artifacts left

**Verify**:
```yaml
acceptance:
  - given: ["All TODOs complete", "Test project URL provided"]
    when: "/study-project <url> is executed"
    then: ["Lesson document created", "State file updated", "No errors"]
commands:
  - run: "test -d docs/lessons/"
    expect: "exit 0"
  - run: "ls docs/lessons/*.md | head -1"
    expect: "exit 0"
  - run: "head -20 docs/lessons/*.md | grep -q '^#'"
    expect: "exit 0"
manual: true
risk: LOW
```

---

## TODO Final: Verification

**Type**: `verification`
**Required Tools**: Bash, Read
**Inputs**: Completed implementation
**Outputs**: Verification status

**Acceptance Criteria**:

**Functional**:
- [ ] `/study-project` command executes successfully
- [ ] Lesson document generated with all required sections
- [ ] State tracking works across sessions
- [ ] Hook triggers on skill completion

**Static**:
- [ ] All skill/agent files have valid YAML frontmatter
- [ ] settings.json is valid JSON
- [ ] Hook script has valid bash syntax
- [ ] No lint errors in markdown files

**Runtime**:
- [ ] ATDD workflow still functions (no regression)
- [ ] Hook registration doesn't conflict with existing hooks
- [ ] State file created and updated correctly

**Verify**:
```yaml
acceptance:
  - given: ["Implementation complete", "All files in place"]
    when: "Verification suite runs"
    then: ["All A-items pass", "H-items ready for human review"]
commands:
  # File existence checks
  - run: "test -f .claude/skills/study-project/SKILL.md"
    expect: "exit 0"
  - run: "test -f .claude/agents/project-analyzer.md"
    expect: "exit 0"
  - run: "test -f .claude/agents/lesson-generator.md"
    expect: "exit 0"
  - run: "test -f .claude/scripts/lesson-hook.sh"
    expect: "exit 0"

  # YAML/JSON validation
  - run: "grep -c '^---' .claude/skills/study-project/SKILL.md | grep -q '^2$'"
    expect: "exit 0"
  - run: "jq empty .claude/settings.json"
    expect: "exit 0"

  # Hook registration
  - run: "jq -r '.hooks | has(\"lesson-stop\")' .claude/settings.json | grep -q 'true'"
    expect: "exit 0"

  # Bash syntax
  - run: "bash -n .claude/scripts/lesson-hook.sh"
    expect: "exit 0"
risk: LOW
```

## Verification Summary

### Agent-Verifiable (A-items)
| ID | Check | Command |
|----|-------|---------|
| A-1 | Skill file exists | `test -f .claude/skills/study-project/SKILL.md` |
| A-2 | Agent files exist (2) | `test -f .claude/agents/project-analyzer.md && test -f .claude/agents/lesson-generator.md` |
| A-3 | Skill YAML valid | `grep -c '^---' .claude/skills/study-project/SKILL.md \| grep -q '^2$'` |
| A-4 | Agent YAML valid | `grep -c '^---' .claude/agents/*.md` |
| A-5 | Hook script exists | `test -f .claude/scripts/lesson-hook.sh` |
| A-6 | Hook script syntax | `bash -n .claude/scripts/lesson-hook.sh` |
| A-7 | Hook registered | `jq -r '.hooks \| has("lesson-stop")' .claude/settings.json \| grep -q 'true'` |
| A-8 | Output dir exists | `test -d docs/lessons` |
| A-9 | Lesson file markdown | `head -20 docs/lessons/*.md \| grep -q '^#'` |
| A-10 | Lesson has sections | `grep -E '^(# Project URL\|# Study Date\|# Architecture\|# Key Design Patterns\|# Lessons Learned)' docs/lessons/*.md` |

### Human-Required (H-items)
| ID | Check | Reason |
|----|-------|--------|
| H-1 | Lesson content quality | Domain expertise needed to assess accuracy |
| H-2 | Question relevance | User experience judgment |
| H-3 | Code example selection | Pedagogical value assessment |
| H-4 | Completeness vs verbosity | Subjective balance judgment |
| H-5 | Architecture insight accuracy | Manual code verification required |
| H-6 | Web reading effectiveness | Verify successful repo analysis |

### External Dependencies Strategy
| Dependency | Strategy |
|------------|----------|
| GitHub Repository | Use real via web reader |
| mcp__web_reader__webReader | Built-in tool |
| docs/lessons/ | Create if missing |
| .claude/settings.json | Edit with backup |
| Bash shell | Use real (no mock) |
