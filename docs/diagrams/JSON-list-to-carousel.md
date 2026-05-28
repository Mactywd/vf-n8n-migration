# JSON list to carousel with random image

**Total nodes:** 36  
**Role:** Renders a list of essence KB chunks as an image carousel; handles user selection from the carousel; manages the "More" / "Altro" pagination option; processes the chosen essence and adds it to the running selection; optionally loops back to the KB Search 48-node flow for additional chunks.  
**Diagram type:** COMPONENT (reusable sub-flow; also registered as flow "Show Essence Carousel")  
**Called from:**
- ROOT > `Show Essences Carousel` block
- ROOT > (second loose invocation — no named block parent)  
**Returns to:**
- Implicit component return to caller (ROOT) after selection is processed
- Or loops to `KB Search` > `Query Generation` block via goToNode when user selects "More/Altro"

---

## Block: New Block 8 (entry check)

**Purpose:** Entry router — checks whether `bypass_kbsearch_chunks` is set, deciding whether to use live KB data or a pre-set `final_chunks` value.  
**Entry point:** Yes — start node (`6885f39ead9cfa0007921f80`) connects here.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c4bb8d1602720cb85d59` | condition-v3 | `bypass_kbsearch_chunks` is `"0"` | match (`cmffr4kch01u52a7ssmr7ktpr`) → `Create Carousel`; else → `New Block 9 copy` |

---

## Block: New Block 9 copy

**Purpose:** Sets `final_chunks` from the `bypass_kbsearch_chunks` variable value and resets `bypass_kbsearch_chunks` to `"0"`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c4bb8d1602720cb85d56` | set-v3 | `final_chunks` = `{bypass_kbsearch_chunks}`; `bypass_kbsearch_chunks` = `"0"` | next → `New Block 12` |

---

## Block: New Block 12

**Purpose:** Sets `shouldSaveName` = `"true"` before building the carousel (signals that a name should be saved on selection).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c4d18d1602720cb85d6e` | set-v3 | `shouldSaveName` = `"true"` | next → `Create Carousel` |

---

## Block: Create Carousel

**Purpose:** Builds the carousel data structure from `final_chunks` / `chunks` using the **Create Carousel** function.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885fc672ca72f007ceed588` | function | **Create Carousel** (fnID `6885fa71436ce39aa3ac57ed`) — inputs: `chunks`, `final_chunks`, `finalChunks`, `defaultLanguage`; outputs: `parsed_chunks`, `carouselData`, `IDs` | port (error) → `Error Message`; port (success) → `New Block 74` |

---

## Block: Error Message

**Purpose:** Displays an error message if carousel creation fails, then exits the flow.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68868ec71059d997d6b331eb` | message | Error message to user | next → ACTIONS (exit) |

---

## Block: New Block 74 (main carousel interaction)

**Purpose:** Sets "More/Altro" button labels, shows the language-aware button via Show Lamguage Buttons component, then checks if user chose "Altro/More".

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692ab16c495dfc3e0aa3efdd` | set-v3 | `italian_labels` = `"Altro"`; `english_labels` = `"More"` | next → (sequential) |
| `692ab16c495dfc3e0aa3efe0` | component | Calls **Show Lamguage Buttons** diagram (`690f5cea514a87470772f220`) | next → (sequential) |
| `692ab16c495dfc3e0aa3efe3` | condition-v3 | `final_label` is `"Altro"` | match (`cmik1fs29036f28811ca5zxcm`) → `New Block 13` (Manage Blacklist → loop to KB); else → `New Block 13 (shouldSaveName check)` |

---

## Block: New Block 13 (Manage Blacklist + loop to KB)

**Purpose:** Adds the current carousel's essences to the blacklist, then jumps back to the KB Search 48 flow to fetch more results.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68d43c9dcc66e9190de505bd` | function | **Manage Blacklisted Essences** (fnID `68d43c2f7fe5c16f8da8f363`) — inputs: `action`, `newEssences`, `blacklistEssences`; outputs: `updatesEssences`, `updatedEssences` | port (success) → ACTIONS (goToNode KB Search 48 `Query Generation`); port (fail) → (none) |

---

## Block: New Block 13 (shouldSaveName check)

**Purpose:** Routes based on whether a name should be saved with the selection.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c52b8d1602720cb85d78` | condition-v3 | `shouldSaveName` is `"true"` | match (`cmke8olmd028g287n0yiicbvo`) → `New Block 14`; else → `New Block 8` (Post-Process Selection) |

---

## Block: New Block 14

**Purpose:** Resets `shouldSaveName` = `"0"` and captures `pathInfoValue` = `{last_utterance}` before re-routing to Post-Process Selection.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c5458d1602720cb85d86` | set-v3 | `shouldSaveName` = `"0"`; `pathInfoValue` = `{last_utterance}` | next → `New Block 8` (Post-Process Selection) |

---

## Block: New Block 8 (Post-Process Selection)

**Purpose:** Runs **Post Process Essences** to confirm the selected chunk matches a valid essence.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899f6d1321a340e6b77a536` | function | **Post Process Essences** (fnID `6899c2130a2a1fc690dab147`) — inputs: `essences`, `essenceNames`; outputs: `rightChunks`, `excludedChunks` | port (match) → `Post-Process Selection`; port (no match) → (none) |

---

## Block: Post-Process Selection

**Purpose:** Parses the raw KB chunk into a structured content object using **Process Selected Chunk**.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6889eb52b3b2df2154122c0e` | function | **Process Selected Chunk** (fnID `6888d15828d89b3c3ef205a3`) — input: `chunk`; output: `content` | port `6888dc6f28d89b3c3ef209f7` → `Add Essence to Selection`; default/fail → (none) |

---

## Block: Add Essence to Selection

**Purpose:** Appends the processed chunk to the `selectedChunks` array and updates `selectedChunksLength`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c0731aef2055ba016de11d` | function | **Add Essence to Selection** (fnID `68c0731e64b6a42fb8cf99c7`) — inputs: `selectedChunk`, `selectedChunks`; outputs: `selectedChunksLength`, `selectedChunks` | default → (exits component — returns to caller) |

---

## Block: Add Selection to Selections

**Purpose:** Alternate code-based path for adding selection (legacy/fallback — parses `selectedChunks` and `selectedChunk` from JSON strings).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6889ed74b3b2df2154122db1` | code | `selectedChunks = JSON.parse(selectedChunks); selectedChunk = JSON.parse(selectedChunk);` | next → (none); fail → (none) |

---

## Unnamed / Utility Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f39ead9cfa0007921f80` | start | Entry point | next → `New Block 8` (entry check) |
| `68868ed51059d997d6b331f4` | exit | Exits the flow on error | — |
| `68868ed51059d997d6b331f5` | actions | Container for the exit node | steps = `[68868ed51059d997d6b331f4]` |
| `6888c31970e5d624b3fbb39d` | set-v3 | `final_chunks` = hardcoded sample JSON (test/debug value) | next → (none — disconnected) |
| `6888caf770e5d624b3fbb3ab` | markup_text | Visual annotation / comment | no connections |
| `68dd46bd6d835a853504dd97` | goToNode | Jump to KB Search 48 node `6885f12a2ca72f007ceed325` (`Query Generation` block) | (exits diagram to KB Search 48) |
| `68dd46bd6d835a853504dd98` | actions | Container for the goToNode above | steps = `[68dd46bd6d835a853504dd97]` |

---

## Flow Summary

```
START → New Block 8 (bypass check)
  [bypass_kbsearch_chunks == "0"] → Create Carousel (direct)
  [else]                          → New Block 9 copy (set final_chunks from bypass var)
                                    → New Block 12 (shouldSaveName = "true")
                                      → Create Carousel

Create Carousel (Create Carousel fn)
  [error]   → Error Message → EXIT
  [success] → New Block 74 (set labels + Show Lamguage Buttons component + condition)
      [final_label == "Altro"] → New Block 13 (Manage Blacklisted Essences)
                                   → goToNode KB Search 48:Query Generation (loop for more)
      [else]                   → New Block 13 (shouldSaveName check)
          [shouldSaveName == "true"]  → New Block 14 (reset shouldSaveName, capture pathInfoValue)
                                         → New Block 8 / Post-Process Selection
          [shouldSaveName != "true"]  → New Block 8 / Post-Process Selection

Post-Process Selection:
  New Block 8 (Post Process Essences fn)
    [match] → Post-Process Selection (Process Selected Chunk fn)
                → Add Essence to Selection (Add Essence to Selection fn)
                    → (returns to caller ROOT)
```
