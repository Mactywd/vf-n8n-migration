# KB Search (24-node version)

**Total nodes:** 24  
**Role:** Legacy/routing-agent variant of the KB Search flow. Uses a Memory Extraction Agent and a Sorting Agent to determine which path to take; performs a knowledge-base search and routes results back to a markup display or exits via goToNode. Older architecture — superseded by the 48-node version.  
**Diagram type:** TOPIC (standalone flow, not called as a component from ROOT in the current build)  
**Called from:** Standalone TOPIC flow. No component invocations found in ROOT or other diagrams. Likely replaced by the 48-node KB Search in production.  
**Returns to:** ROOT via goToNode → `687d00e126a84c8635cfb34a`

---

## Block: (trigger wrapper — unnamed)

**Purpose:** Wraps the trigger node that starts this standalone TOPIC flow.  
**Entry point:** Yes

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f00fc89354000779119c` | trigger | Flow entry trigger | next → (none — trigger has no outbound target in data) |

---

## Block: New Block 7

**Purpose:** Sets `essence_descriptions` then shows a message (first iteration of description loading).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1a9` | set-v3 | `essence_descriptions` = prompt ref `688150fe31f495035b1da4af` | next → (sequential) |
| `6885f0132ca72f007ceed1ac` | message | Display message after setting descriptions | next → (none in data) |

---

## Block: New Block 6

**Purpose:** Sets `long_thought` then shows a message (thinking/loading indicator for extended reasoning).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1af` | set-v3 | `long_thought` = prompt ref `687f9ab80b2e7b4455a46cb8` | next → (sequential) |
| `6885f0132ca72f007ceed1b2` | message | Display thinking message | next → `New Block 7` (loopback) |

---

## Block: Post Processing

**Purpose:** Sets `fast_thought` then shows a message (quick/abbreviated reasoning indicator).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1b5` | set-v3 | `fast_thought` = prompt ref `687f9c9c0b2e7b4455a46cc1` | next → (sequential) |
| `6885f0132ca72f007ceed1b8` | message | Display post-processing message | next → `New Block 6` |

---

## Block: Memory Extraction Agent

**Purpose:** Runs the Memory Extraction Agent (agentID `687d0459822de29a91ac2294`) to extract sensory memory details from user input.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1bb` | agent | **Memory Extraction Agent** (agentID `687d0459822de29a91ac2294`) | port `687ea33914419341cec93e78` → `Query Generation`; port `687ea33d14419341cec93e7f` → ACTIONS (goToNode ROOT exit) |

---

## Block: Perfume Extraction Agent

**Purpose:** Sends a message after the "Perfume Extraction" path (placeholder / alternate output route).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1bf` | message | Message after perfume extraction | next → (none) |

---

## Block: Query Generation

**Purpose:** Sets `essence_query`, shows a "searching..." message, performs the KB search, then routes to Post Processing.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1c2` | set-v3 | `essence_query` = prompt ref `687f9ab30b2e7b4455a46cb5` | next → (sequential) |
| `6885f0132ca72f007ceed1c5` | message | "Searching…" indicator message | next → (sequential) |
| `6885f0132ca72f007ceed1c8` | kb-search | query = `{essence_query}`, maxChunks = 3, results → `kb_results` | next → `Post Processing` |

---

## Block: Routing Agent

**Purpose:** Runs the Sorting Agent (agentID `67db2b56cbe88befffef4623`) to route to Memory Extraction or Perfume Extraction path.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1cb` | agent | **Sorting Agent** (agentID `67db2b56cbe88befffef4623`) | port `687cfe61822de29a91ac1fbd` → `Memory Extraction Agent`; port `687cffbf822de29a91ac2081` → `Perfume Extraction Agent` |

---

## Unnamed Blocks

These blocks are outer wrappers for the above nodes and do not add further logic:

| block_id | steps | notes |
|----------|-------|-------|
| `6885f00fc89354000779119d` | `[trigger]` | Trigger wrapper |

---

## Non-Block Nodes (loose)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f0132ca72f007ceed1a7` | actions | Container for the goToNode exit step | steps = `[6885f0132ca72f007ceed1cf]` |
| `6885f0132ca72f007ceed1cf` | goToNode | Jump to ROOT node `687d00e126a84c8635cfb34a` | (exits diagram) |
| `6885f0132ca72f007ceed1ce` | markup_text | Visual annotation / comment; no outbound connection | — |

---

## Flow Summary

```
TRIGGER
  → Routing Agent (Sorting Agent)
      [Memory path]  → Memory Extraction Agent
                          [continue] → Query Generation
                                         → KB Search → Post Processing (fast_thought msg)
                                                           → New Block 6 (long_thought msg)
                                                               → New Block 7 (descriptions msg)
                          [exit]     → ACTIONS → goToNode ROOT:687d00e126a84c8635cfb34a
      [Perfume path] → Perfume Extraction Agent (message, no further routing)

markup_text: standalone annotation node (orphan)
```

> **Migration note:** This 24-node version is the older TOPIC-based design. The 48-node COMPONENT version (`KB-Search-48.md`) is the active production flow. When migrating to n8n, use the 48-node version as the primary reference; this file documents the legacy architecture for context.
