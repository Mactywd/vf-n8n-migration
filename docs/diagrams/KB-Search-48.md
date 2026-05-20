# KB Search (48-node version)

**Total nodes:** 48  
**Role:** Iterative essence discovery loop — generates KB queries, searches the knowledge base for matching essences, presents them via carousel, captures user selections, and either loops for more or finalises with an acknowledgement.  
**Diagram type:** COMPONENT (reusable sub-flow)  
**Called from:**
- ROOT > `Get Essences` block
- ROOT > (second invocation, loose — no named block parent)  
**Returns to:**
- ROOT > `692731af0336de0f8ef0fcc5` (via goToNode after "Choice Description" path)
- ROOT > `690f8540c501166d01777772` (via goToNode after "Acknowledge Selections" path)

---

## Block: Fast Thought

**Purpose:** Sets the `long_thought` prompt variable to seed the initial descriptive thinking context.  
**Entry point:** No — entered from start node via Block 15 (New Block 15).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f12a2ca72f007ceed32d` | set-v3 | `long_thought` = prompt ref `6907624e353d04e3f7b4fbf9` | next → (none — sequential within block) |
| `68935f207423b768f0832bc7` | set-v3 | `essence_descriptions` = prompt ref `6907624e353d04e3f7b4fbdf` | next → `6989b8e1ffa84124e19e2279` |

---

## Block: Query Generation

**Purpose:** Builds the KB search query by setting `essence_query`, then performs the KB search.  
**Entry point:** No — looped into from New Block 5 and New Block 16.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f12a2ca72f007ceed339` | set-v3 | `essence_query` = prompt ref `6907624e353d04e3f7b4fbf7` | next → (sequential) |
| `68f8feb589c941c592df20d7` | set-v3 | `essence_query` = prompt ref `6907624e353d04e3f7b4fbef` (alternate phrasing) | next → (sequential) |
| `6885f12a2ca72f007ceed33f` | kb-search | query = `{essence_query}`, maxChunks = 10, results → `kb_results` | next → `68934c0c87710eb03daf29bf` |

---

## Block: Remove Duplicates

**Purpose:** Filters already-selected and blacklisted essences out of the raw KB results.  
**Entry point:** No — entered from KB search output.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68934c0c87710eb03daf29bd` | function | **Remove Chosen Essences** — inputs: `kbChunks`, `selectedChunks`, `blacklistEssences`, `beforeAltro`, `prevCarousel`; output: `processedChunks` | default → (none); port `688a11c934582772f5ad54fc` → `Fast Thought` block (loop if no usable results); port `688a11c934582772f5ad54fd` → `New Block 5` |

---

## Block: New Block 5

**Purpose:** Resets `blacklistEssences` to `[]` before launching a fresh query generation cycle.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69834fe85f3460c63c4fb533` | set-v3 | `blacklistEssences` = `[]` | next → `Query Generation` block |

---

## Block: New Block 11

**Purpose:** Post-processes the filtered essence list to ensure correct naming.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6899c21275c76d52737df62b` | function | **Post Process Essences** — inputs: `essenceNames`, `essences`; outputs: `rightChunks`, `excludedChunks` | port (match) → `New Block 7`; port (no match) → `New Block 5` |

---

## Block: New Block 7

**Purpose:** Generates the poetic "Choice Description" for each KB chunk shown to the user.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c2e48890aacf5de8985736` | response-prompt | **Choice Description** agent response (promptID `6907624e353d04e3f7b4fbd4`) | next → ACTIONS `692731bf0336de0f8ef0fd4e` (goToNode → ROOT `692731af0336de0f8ef0fcc5`) |

---

## Block: New Block 15

**Purpose:** Sets `pre_kb_thought` context then launches the Pre KB-Search Question agent response.  
**Entry point:** Yes — receives the diagram start node (`6885f11ec8935400077911a3`) via start → `692318a60119176dcc69fa4c`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68f51afdb355311c3be20109` | set-v3 | `pre_kb_thought` = prompt ref `6907624e353d04e3f7b4fbd9` | next → (sequential) |
| `68e6989bdb1b3f397b0ae487` | response-prompt | **Pre KB-Search Question** (promptID `6907624e353d04e3f7b4fbf8`) — asks clarifying question before KB search | next → `New Block 10` |

---

## Block: New Block 10

**Purpose:** Sets the `examples` context variable and conditionally adds the "finish your dream" option if multiple essences already selected.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68e7e355bca4f07bb1279fe5` | set-v3 | `examples` = prompt ref `6907624e353d04e3f7b4fc02` | next → (sequential) |
| `6909cfc61eb3afbb2fb11b20` | code | If `selectedChunksLength > 1`, push "Concludi il tuo sogno" / "Finish your dream" into `examples` JSON array | next → `New Block 16` (Show Buttons) |

---

## Block: New Block 16 (Show Buttons)

**Purpose:** Calls **Show Buttons** function to render clickable essence options.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `693d7edf7f25f5a43c236408` | function | **Show Buttons** — input: `labels`; renders buttons | default → `New Block 17` (Capture + random seed) |

---

## Block: New Block 17 (Capture + Random Seed)

**Purpose:** Seeds randomness for image selection and captures the user's essence choice.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a96bef84f247548fb4927` | set-v3 | `userCanWrite` = `Math.random()` (random seed) | next → (sequential) |
| `693d7ef77f25f5a43c236412` | capture-v3 | Captures user reply → `last_utterance` | next → `New Block 74` |

---

## Block: New Block 74

**Purpose:** Checks if user typed "Concludi il tuo sogno" / "Finish your dream" to exit the loop.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692ab1eb495dfc3e0aa3f2ed` | condition-v3 | `last_utterance` is "Concludi il tuo sogno" OR "Finish your dream" | match → `New Block 17` (Acknowledge); else → `New Block 14` |

---

## Block: New Block 14

**Purpose:** Sets `categoria_followup` variable and checks whether the answer matches the follow-up category logic.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692318390119176dcc69fa3c` | set-v3 | `categoria_followup` = prompt ref `6923181211b7bee990cbc971` | next → (sequential) |
| `692318560119176dcc69fa41` | condition-v3 | `categoria_followup` is "avanti" | match → `Add Q&A to List`; else → `New Block 16` (re-show buttons) |

---

## Block: New Block 16 (Message — re-route)

**Purpose:** Sends a loopback message before re-entering the Pre KB-Search Question cycle.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692318e80119176dcc69fa5c` | message | Informational message (loopback) | next → `New Block 10` (Pre KB-Search Question) |

---

## Block: Add Q&A to List

**Purpose:** Appends the current question/answer pair to `qna_list` to refine future KB queries.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68e69c8cdb1b3f397b0ae4b3` | code | `qna_list += last_response + "\n" + last_utterance + "\n"` | next → `New Block 16` (set user_query + loop to Query Generation) |

---

## Block: New Block 16 (user_query setter)

**Purpose:** Saves the last utterance as the active `user_query` for the next KB search iteration.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `698744d4fd86cd3abe89c17a` | set-v3 | `user_query` = `{last_utterance}` | next → `Query Generation` block |

---

## Block: New Block 17 (Acknowledge Selections)

**Purpose:** Agent generates a poetic acknowledgement of the user's final essence selections, then exits to ROOT.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69275a26166b96a02889b841` | response-prompt | **Acknowledge Selections** (promptID `6907624e353d04e3f7b4fbf3`) | next → ACTIONS `69275a32166b96a02889b84b` |

---

## Block: New Block 17 (final exit — goToNode)

**Purpose:** Jumps back to ROOT after "Acknowledge Selections" (different block from above; exits to `690f8540c501166d01777772` in ROOT).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69275a32166b96a02889b84a` | goToNode | Jump to ROOT node `690f8540c501166d01777772` | (exits diagram) |

---

## Block: New Block 17 (post-condition exit — goToNode)

**Purpose:** Exits to ROOT node `692731af0336de0f8ef0fcc5` after the "Choice Description" path.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692731bf0336de0f8ef0fd4d` | goToNode | Jump to ROOT node `692731af0336de0f8ef0fcc5` | (exits diagram) |

---

## Block: New Block 17 (post-condition — KB result routing)

**Purpose:** Routes to the correct processing block based on whether KB results pass the essence filter condition.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6989b8e1ffa84124e19e2276` | condition-v3 | Prompt-based condition (promptID `6989b8ea0b8532b309777e51`) — two output paths | path 1 (`cmlf1g64100qh3b8fuu2rxudw`) → `New Block 11`; path 2 (`cmlf1g9t300vl3b8fdxov5ozp`) → `Fast Thought` block |

---

## Start Node

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6885f11ec8935400077911a3` | start | Entry point — "Enter" | next → `New Block 15` |

---

## Unused / Orphan Nodes

| node_id | type | notes |
|---------|------|-------|
| `6885fc102ca72f007ceed54b` | code | Empty code body; appears to be a placeholder (no connections outward) |
| `6885fc102ca72f007ceed54c` | actions | Container for the above orphan code node |

---

## Flow Summary

```
START → New Block 15 (pre_kb_thought + Pre KB-Search Question)
  → New Block 10 (examples + Show Buttons conditional)
    → New Block 16 (Show Buttons)
      → New Block 17 (Capture)
        → New Block 74 (finish check)
          [finish] → New Block 17 (Acknowledge Selections) → goToNode ROOT:690f8540c501166d01777772
          [continue] → New Block 14 (categoria_followup check)
            [avanti] → Add Q&A to List → user_query setter → Query Generation
            [not avanti] → re-show buttons loop
            
Query Generation → KB Search → Remove Duplicates
  [no useful results] → Fast Thought → Query Generation (loop)
  [useful results]    → New Block 5 (reset blacklist) → Query Generation  OR
                         New Block 11 (Post Process) → 
                           [match] → New Block 7 (Choice Description) → goToNode ROOT:692731af0336de0f8ef0fcc5
                           [no match] → New Block 5 (loop)
                           
Fast Thought → KB results condition
  → New Block 11 or Fast Thought loop
```
