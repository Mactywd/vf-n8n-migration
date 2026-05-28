# Perfect Prompt Generator

**Total nodes:** 10  
**Role:** Standalone prompt-building flow — asks the user two questions (use case and usage examples), collects their answers, then runs an AI agent to synthesise the information into a polished final fragrance prompt.  
**Diagram type:** TOPIC (standalone flow with its own trigger; not invoked as a component from ROOT in the current build)  
**Called from:** Standalone TOPIC flow. No component references found in ROOT or other diagrams. Likely intended as an optional debug / standalone entry point for generating fragrance prompts directly.  
**Returns to:** N/A (no goToNode or explicit return; flow ends after the response-prompt node)

---

## Block: (trigger wrapper — unnamed)

**Purpose:** Wraps the trigger node that starts this standalone TOPIC flow.  
**Entry point:** Yes

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899a65b4d3651000753e7f4` | trigger | Flow entry trigger | next → first message node (`6899a66575c76d52737df053`) |

---

## Block: New Block 1

**Purpose:** Asks the user about the use case (what the perfume is for) and captures their response.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899a66575c76d52737df053` | message | First prompt question — asks for use-case context (msgID `6899a6660a2a1fc690daaabd`) | next → (sequential within block) |
| `6899a66f75c76d52737df05c` | capture-v3 | Captures user reply → `usecaseinfo` | next → second message (`6899a68475c76d52737df062`) |

---

## Block: New Block 2

**Purpose:** Asks the user for usage examples and captures their response.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899a68475c76d52737df062` | message | Second prompt question — asks for usage examples (msgID `6899a6840a2a1fc690daaae1`) | next → (sequential within block) |
| `6899a68e75c76d52737df06b` | capture-v3 | Captures user reply → `examplesusage` | next → response-prompt (`6899a6a275c76d52737df071`) |

---

## Block: New Block 3

**Purpose:** Runs an AI agent response to generate the final "perfect prompt" from the collected `usecaseinfo` and `examplesusage` context.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899a6a275c76d52737df071` | response-prompt | **Untitled prompt** (promptID `6899a6a962a63cde30bfe4ff`) — synthesises `usecaseinfo` + `examplesusage` into a final fragrance prompt | next → (none — end of flow) |

---

## Flow Summary

```
TRIGGER
  → New Block 1
      MESSAGE (use-case question)
      CAPTURE → usecaseinfo
        → New Block 2
            MESSAGE (examples question)
            CAPTURE → examplesusage
              → New Block 3
                  RESPONSE-PROMPT (generate perfect prompt from usecaseinfo + examplesusage)
                    → (flow ends)
```

## Key Variables

| variable | direction | description |
|----------|-----------|-------------|
| `usecaseinfo` | output | User's description of the use case / occasion for the perfume |
| `examplesusage` | output | User's description of usage examples / occasions |
