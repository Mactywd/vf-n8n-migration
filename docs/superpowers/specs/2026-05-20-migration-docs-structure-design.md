# Design: Voiceflow → n8n Migration Documentation Structure

**Date:** 2026-05-20  
**Goal:** Organize detailed Voiceflow flow documentation into files and folders to serve as AI context during n8n migration sessions.

---

## Context

The source file `alchimista.json` is a 1.5 MB Voiceflow v13.09 export (~37,000 lines). Currently the only documentation is `CLAUDE.md`, which provides a high-level overview. The migration requires Claude to understand:

- Every node in every diagram (type, config, ports, connections)
- Full agent system prompts and routing logic
- Full JavaScript function code with inputs/outputs
- All 101 state variables and who reads/writes them
- How the 9 Voiceflow node types map to n8n equivalents

The docs are **primarily for AI context** — loaded selectively per migration session to avoid burning tokens on irrelevant content.

---

## Approach: C — Navigation-first with index

A nested folder structure (diagrams / agents / functions) plus a top-level index file that tells Claude which files to load for each migration task.

---

## File Tree

```
docs/
  00-index.md                          ← task-to-file mapping for AI navigation
  migration-mapping.md                 ← Voiceflow node type → n8n equivalent (all types)
  variables.md                         ← all 101 variables: name, type, default, readers/writers
  diagrams/
    ROOT.md                            ← all 314 nodes organized by named block
    KB-Search-48.md                    ← 48-node KB search loop
    KB-Search-24.md                    ← 24-node routing-agent version
    Select-Essence.md                  ← 11-node button-based essence selection UI
    JSON-list-to-carousel.md           ← 36-node carousel rendering pipeline
    Target-Selector.md                 ← 12-node agent-driven gender selection
    Perfume-Type-Selector.md           ← 7-node home vs. personal gift choice
    Show-Language-Buttons.md           ← 9-node language selector
    Perfect-Prompt-Generator.md        ← 10-node final prompt generator
  agents/
    routing-agent.md
    memory-extraction-agent.md
    target-agent.md
    sorting-agent.md
    essence-selection-agent.md
    choice-description-agent.md
    carousel-pipeline-agents.md        ← 4 carousel agents documented together (pipeline)
  functions/
    create-carousel.md
    create-essence-carousel.md
    create-essence-buttons.md
    show-buttons.md
    add-essence-to-selection.md
    remove-essence.md
    process-selected-chunk.md
    post-process-essences.md
    remove-chosen-essences.md
    manage-blacklisted-essences.md
    update-chunk-to-fetch.md
    add-fetched-chunk.md
    verify-id.md
    create-general-info.md
    show-languaged-buttons.md
    find-italian-choice.md
```

---

## File Formats

### `00-index.md`

For each n8n migration task, lists which docs files to load. Format:

```markdown
## Task: Migrate Routing Agent
Files: agents/routing-agent.md, variables.md (rows: default_language, target_gender)

## Task: Migrate ROOT > Intro + Gender Select block
Files: diagrams/ROOT.md#intro-gender-select, agents/target-agent.md, agents/routing-agent.md

## Task: Migrate KB Search (48-node)
Files: diagrams/KB-Search-48.md, functions/update-chunk-to-fetch.md,
       functions/add-fetched-chunk.md, functions/remove-chosen-essences.md, variables.md
```

### `diagrams/ROOT.md` (and other diagram files)

Organized by named block. Unnamed blocks ("New Block N") grouped by functional proximity to their nearest named block. For each block:

```markdown
## Block: Intro + Gender Select
**Purpose:** one-sentence description
**Entry point:** yes/no
**Exits to:** list of downstream blocks/diagrams

### Nodes
| node_id | type | config summary | ports → next_node_id |
|---------|------|----------------|----------------------|
| abc123  | start | — | default → def456 |
| def456  | set-v3 | default_language = "it" | next → ghi789 |
| ghi789  | response-prompt | agent: Target Agent | confirmed → jkl012 |
```

Unnamed blocks that are sub-steps of a named block are listed inline under that block with a note like `(unnamed sub-step of "Intro + Gender Select")`. Truly orphaned unnamed blocks (no nearby named block) get a section `## Unnamed Blocks` at the bottom of the file, with a brief inferred purpose based on their node types and connections.

### `agents/<name>.md`

```markdown
## <Agent Name>

**Voiceflow ID:** <uuid>
**Model/settings:** <from agent.settings>
**Reads variables:** comma-separated list
**Writes variables:** comma-separated list (if any)

### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| Route to Memory | user chooses memory path | ROOT > Memory Path Intro |

### System Prompt
[full prompt text, verbatim]

### n8n Migration Notes
- Map to: AI Agent node
- Output paths → Switch node with N branches (one per path)
- Variable reads → Set node upstream, passed as $json fields
```

### `functions/<name>.md`

```markdown
## <Function Name>

**Voiceflow ID:** <uuid>
**Input variables:** name (type) — description
**Output variables:** name (type) — description
**Called from:** ROOT > <Block Name> or <Diagram Name>

### Code
```typescript
export default async function main(args) {
  // full code verbatim
}
```

### n8n Migration Notes
- Map to: Code node (JavaScript mode)
- Inputs: accessible as `$input.first().json.<varName>`
- Outputs: return as `{ <outputVar>: value }`
```

### `variables.md`

```markdown
| Variable | Type | Default | Description | Read by | Written by |
|----------|------|---------|-------------|---------|------------|
| target_gender | string | "" | Uomo/Donna/Unisex | Sorting Agent, Memory Extraction Agent | Target Selector diagram |
...
```

### `migration-mapping.md`

```markdown
| Voiceflow type | Count in ROOT | n8n equivalent | Notes |
|----------------|--------------|----------------|-------|
| block | 101 | — | Logical grouping only, no n8n node needed |
| set-v3 | 55 | Set node | ... |
| response-prompt | 27 | AI Agent node | Agent prompt referenced in agents/ |
...
```

---

## Generation Strategy

All files are generated by a script (or Claude session) that parses `alchimista.json` programmatically. The source of truth is always `alchimista.json` — docs are derived, not hand-written. If the source changes, regenerate.

Generation order:
1. `variables.md` — no dependencies
2. `migration-mapping.md` — no dependencies  
3. `agents/*.md` — depends on variables.md for cross-refs
4. `functions/*.md` — depends on variables.md
5. `diagrams/*.md` — depends on agents and functions (for cross-refs in node tables)
6. `00-index.md` — depends on all diagrams, summarizes them

---

## Out of Scope

- `intents`, `utterances`, `entities` from Voiceflow (not used in this flow)
- `simulations` / `transcripts` (test data, not needed for migration)
- Voiceflow `personas` (style is captured in agent prompts already)
