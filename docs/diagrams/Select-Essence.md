# Select Essence

**Total nodes:** 11  
**Role:** Button-based essence selection UI — presents currently-selected essences as clickable buttons, captures the user's button press, performs a focused KB search for that essence by name, then parses the KB chunk into a structured essence object ready for the selection list.  
**Diagram type:** COMPONENT (reusable sub-flow)  
**Called from:** ROOT > `Prompt Enhance Essence` block  
**Returns to:** Caller (ROOT) via implicit component return after last node

---

## Block: Create Buttons

**Purpose:** Renders the current list of selected essences as interactive buttons so the user can choose one.  
**Entry point:** Yes — start node (`688f34ab7291a60006a6a8e5`) connects here.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f34bc36d5ca4fd32d10c6` | function | **Create Essence Buttons** (fnID `688f333c17643c0ee1a20087`) — input: `selectedChunks`; renders buttons for each selected essence | default → `User Selection`; port `68b8aec4d930346a13c99bd3` → (none — no results path) |

---

## Block: User Selection

**Purpose:** Waits for the user to tap or type one of the essence button labels.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f34cc36d5ca4fd32d10cf` | capture-v3 | Captures user reply → `last_utterance` | next → `Retrieve Selection` |

---

## Block: Retrieve Selection

**Purpose:** Searches the KB for the essence the user picked, by constructing a query `"Nome: {last_utterance}"`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f34dd36d5ca4fd32d10d9` | kb-search | query = `"Nome: {last_utterance}"`, maxChunks = 1, results → `selectedEssence` | next → `New Block 4` |

---

## Block: New Block 4

**Purpose:** Filters the KB result to confirm it matches the expected essence, using **Post Process Essences**.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899f982321a340e6b77b14f` | function | **Post Process Essences** (fnID `6899c2130a2a1fc690dab147`) — inputs: `essences`, `essenceNames`; output: `rightChunks` | port (match) → `New Block 5`; port (no match) → (none) |

---

## Block: New Block 5

**Purpose:** Parses the matched KB chunk into a structured essence content object via **Process Selected Chunk**.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899f990321a340e6b77b15c` | function | **Process Selected Chunk** (fnID `6888d15828d89b3c3ef205a3`) — input: `chunk`; output: `content` | port `6888dc6f28d89b3c3ef209f7` → (none — exits component); port `6888dc6a28d89b3c3ef209f5` → (none) |

---

## Start Node

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f34ab7291a60006a6a8e5` | start | Entry point | next → `Create Buttons` |

---

## Flow Summary

```
START → Create Buttons (Create Essence Buttons fn)
  → User Selection (capture last_utterance)
    → Retrieve Selection (KB search: "Nome: {last_utterance}", 1 chunk → selectedEssence)
      → New Block 4 (Post Process Essences — confirm match)
          [match] → New Block 5 (Process Selected Chunk → content)
          [no match] → (exits with no result)
```
