# ROOT Diagram

**Total nodes:** 314  
**Entry point:** `start` → `Intro + Gender Select`  
**Diagrams called (sub-flows):**
- `KB Search` (48 nodes) — main KB search sub-flow
- `KB Search` (24 nodes) — legacy/routing-agent version
- `Select Essence` (11 nodes) — button-based essence UI
- `JSON list to carousel with random image` (36 nodes) — carousel renderer
- `Target Selector` (12 nodes) — Masculine/Feminine/Universal choice
- `Perfume Type Selector` (7 nodes) — Home vs. Personal
- `Show Lamguage Buttons` (9 nodes) — Italian/English button selector (note: diagram name has typo)
- `Perfect Prompt Generator` (10 nodes) — final fragrance prompt builder

---

## Conversation Flow Summary

```
START
  └─ Intro + Gender Select
       └─ New Block 56 (Sorting Agent)
            ├─ [Memory]     New Block 83 → Memory Path Intro → Description Listening → Base Essence Validator
            ├─ [Essence]    New Block 83 copy → Essence Path Intro → [category selection] → KB Search loop
            └─ [Fragrance]  Fragrance Path Intro
                 ├─ [NdC]       New Block 83 copy → KB Search for NdC fragrance
                 └─ [Non-NdC]   New Block 83 copy copy → Non-NdC name capture → Exa API search

KB Search Loop: Get Essences → Show Essences Carousel → Analyze Selected Chunks
  ├─ [<4 essences] → back to Get Essences
  ├─ [4 essences, no enhancement] → Prompt 5th Essence → Amplify or Go On → Finish Perfume Creation
  └─ [4 essences, enhanced] → New Block 55 → Finish Perfume Creation

Finish Perfume Creation → Perfume Intensity → Additional Notes → Naming Ritual → Show Suggestion Buttons → Save Name Reply → Finish Journey → New Block 25 (generalInfo) → END
```

---

## Node Count by Type

| Type | Count | n8n equivalent |
|------|-------|----------------|
| `block` | 101 | Workflow group / sticky note boundary |
| `set-v3` | 55 | Set node |
| `response-prompt` | 27 | AI Agent node (LLM call) |
| `function` | 26 | Code node (JS function call) |
| `actions` | 21 | Internal wrapper container |
| `component` | 17 | Execute Workflow (sub-flow call) |
| `condition-v3` | 16 | If / Switch node |
| `goToNode` | 15 | Execute Workflow / jump |
| `capture-v3` | 9 | Wait for webhook |
| `markup_text` | 8 | Sticky note (visual label, no logic) |
| `kb-search` | 6 | HTTP Request to Voiceflow KB API |
| `exit` | 5 | End node |
| `message` | 4 | Send Message node |
| `code` | 2 | Code node (inline JS) |
| `api-v2` | 1 | HTTP Request (Exa.ai search) |
| `start` | 1 | Trigger node |

---

## Block Reference (sorted by canvas x,y position)

> Blocks are listed left-to-right, top-to-bottom as they appear on the Voiceflow canvas.
> Named blocks have a `**Purpose:**` line. "New Block N" names are Voiceflow auto-assigned defaults.

### Block: Intro + Gender Select
**ID:** `68869c23`  **Coords:** `[-1021, 769]`  **Steps:** 2

**Purpose:** Opening greeting by the Routing Agent (Introduction prompt), followed by Target Selector sub-flow to collect `target_gender` (Uomo / Donna / Unisex).

**Entry point:** yes

**Exits to:** New Block 56 (Sorting Agent path selection)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688a1cfd` | response-prompt | agent prompt: "Introduction" | — |
| `68869c13` | component | call diagram: Target Selector | `next` → New Block 56 |

### Block: New Block 56
**ID:** `690f6f97`  **Coords:** `[-1005, 1060]`  **Steps:** 4

**Purpose:** Sorting Agent block. Presents 3 paths (Memory / Essenza / Fragranza NdC). Sets `italian_labels` / `english_labels` for language-aware buttons, then routes via condition on `final_label`.

**Exits to:** New Block 83 (Memory), New Block 83 copy (Essence), Fragrance Path Intro (Fragrance), New Block 84 (else/fallback)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688a1ec8` | response-prompt | agent prompt: "Path Select" | — |
| `690f6fd7` | set-v3 | italian_labels = 'Memoria,Essenza,Fragranza', english_labels = 'Memory,Essence,Fragrance' | — |
| `690f6f97` | component | call diagram: Show Lamguage Buttons | — |
| `690f700f` | condition-v3 | if final_label == "[{'text': ['Memoria'" / final_label == "[{'text': ['Essenza'" / final_label == "[{'text': ['Fragranz" | `else` → New Block 84, `if final_label=="[{'text': ['Mem"` → New Block 83, `if final_label=="[{'text': ['Ess"` → New Block 83 copy, `if final_label=="[{'text': ['Fra"` → → Fragrance Path Intro |

### Block: New Block 74
**ID:** `6921b108`  **Coords:** `[-617, 1816]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6921b108` | set-v3 | generalInfo = '{"perfumeName":"Aurora di Seta' | `next` → (end flow) |

### Block: New Block 83
**ID:** `6967c22b`  **Coords:** `[-593, 1118]`  **Steps:** 1

**Purpose:** Sets `chosenPath = "Memoria"` and `pathInfoField = "Ricordo"`, then jumps to Memory Path Intro.

**Exits to:** → Memory Path Intro (goToNode)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c22b` | set-v3 | chosenPath = 'Memoria', pathInfoField = 'Ricordo' | `next` → → Memory Path Intro |

### Block: New Block 83 copy
**ID:** `6967c258`  **Coords:** `[-530, 1349]`  **Steps:** 1

**Purpose:** Sets `chosenPath = "Essenza"` and `pathInfoField = "Essenza"`, then jumps to Essence Path Intro.

**Exits to:** → Essence Path Intro (goToNode)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c258` | set-v3 | chosenPath = 'Essenza', pathInfoField = 'Essenza' | `next` → → Essence Path Intro |

### Block: New Block 27
**ID:** `68ae0cb3`  **Coords:** `[-278, 9]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68ae0d02` | set-v3 | conversation_state = 'description-generation' | — |
| `68ae0cb7` | set-v3 | temp_variable = '688f2705479938e87d150075' | — |

### Block: New Block 84
**ID:** `695a92bb`  **Coords:** `[-124, 1664]`  **Steps:** 1

**Purpose:** Fallback path: sends a static message (e.g. error/retry) and ends the flow.

**Exits to:** (end flow)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a92bb` | message | send static message | `next` → (end flow) |

### Block: Fragrance Path Intro
**ID:** `68fcf8f9`  **Coords:** `[455, 3923]`  **Steps:** 4

**Purpose:** Renaissance path intro: asks for NdC fragrance reference. Routes: known NdC fragrance → New Block 83 copy (NdC path); other fragrance → New Block 83 copy copy (non-NdC path).

**Exits to:** New Block 83 copy (NdC), New Block 83 copy copy (other)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690270a0` | response-prompt | agent prompt: "Ask Fragrance Origin" | — |
| `690f7460` | set-v3 | italian_labels = 'Note del Chianti,Altro Profumo', english_labels = 'Note del Chianti,Other Perfume' | — |
| `690f7460` | component | call diagram: Show Lamguage Buttons | — |
| `690f7460` | condition-v3 | if final_label == "[{'text': ['Note del" / final_label == "[{'text': ['Altro Pr" | `if final_label=="[{'text': ['Alt"` → New Block 83 copy copy, `if final_label=="[{'text': ['Not"` → New Block 83 copy |

### Block: Essence Path Intro
**ID:** `68c06f74`  **Coords:** `[735, 2195]`  **Steps:** 1

**Purpose:** First Inspiration path message: Essence Path Intro agent response. Then routes to sub-flow for category selection.

**Exits to:** New Block 74 (category selection)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c070d2` | response-prompt | agent prompt: "Essence Path Intro" | `next` → New Block 74 |

### Block: New Block 74
**ID:** `692ab082`  **Coords:** `[840, 2451]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692ab082` | set-v3 | italian_labels = 'So già quale essenza usare,Aiu', english_labels = 'I know what essence I want,Hel' | — |
| `692ab082` | component | call diagram: Show Lamguage Buttons | — |
| `692ab082` | condition-v3 | if final_label == "[{'text': ['So già q" / final_label == "[{'text': ['Aiutami " | `if final_label=="[{'text': ['Aiu"` → New Block 31, `if final_label=="[{'text': ['So "` → New Block 25 |

### Block: New Block 83 copy
**ID:** `6967c259`  **Coords:** `[842, 4037]`  **Steps:** 1

**Purpose:** Sets `chosenPath = "Essenza"` and `pathInfoField = "Essenza"`, then jumps to Essence Path Intro.

**Exits to:** → Essence Path Intro (goToNode)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c259` | set-v3 | chosenPath = 'Fragranza NdC', pathInfoField = 'Fragranza' | `next` → New Block 52 |

### Block: New Block 83 copy copy
**ID:** `6967c2b8`  **Coords:** `[877, 4358]`  **Steps:** 1

**Purpose:** Sets `chosenPath = "Altra Fragranza"` (non-NdC fragrance path). Exits to New Block 47 (capture non-NdC perfume name).

**Exits to:** New Block 47

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c2b8` | set-v3 | chosenPath = 'Altra Fragranza', pathInfoField = 'Fragranza' | `next` → New Block 47 |

### Block: Memory Path Intro
**ID:** `6887994b`  **Coords:** `[1143, 470]`  **Steps:** 1

**Purpose:** First Memory path message: Memory Extraction Agent prompts the user to describe their memory ("Essence Prompting" response). Flows directly to Description Listening.

**Exits to:** Description Listening

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688a22bb` | response-prompt | agent prompt: "Essence Prompting" | `next` → Description Listening |

### Block: Naming Ritual
**ID:** `68907e9d`  **Coords:** `[1156, -50]`  **Steps:** 2

**Purpose:** Runs Perfume Name Instructions agent, stores `nameSuggestions`. Routes to Show Suggestion Buttons.

**Exits to:** Show Suggestion Buttons

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68b2ec3e` | response-prompt | agent prompt: "Perfume Name Instructions" | — |
| `68907f8a` | set-v3 | nameSuggestions = '6907624e353d04e3f7b4fbd8' | `next` → Show Suggestion Buttons |

### Block: Additional Notes
**ID:** `69440498`  **Coords:** `[1161, -988]`  **Steps:** 1

**Purpose:** Asks for any additional notes (intensity, preferences) via untitled prompt agent. Routes to New Block 74 (Additional Notes collection).

**Exits to:** New Block 74

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69762178` | response-prompt | agent prompt: "Additional Notes Question" | `next` → New Block 74 |

### Block: Perfume Intensity
**ID:** `68d939e9`  **Coords:** `[1185, -342]`  **Steps:** 1

**Purpose:** Captures perfume intensity preference. Routes to New Block 74 (Additional Notes).

**Exits to:** New Block 74

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692aaf41` | response-prompt | agent prompt: "Final Perfume Intensity" | `next` → New Block 74 |

### Block: New Block 52
**ID:** `6902724d`  **Coords:** `[1224, 3564]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6902716e` | response-prompt | agent prompt: "NdC Fragrance Prompter" | `next` → New Block 44 |

### Block: New Block 25
**ID:** `68c07254`  **Coords:** `[1298, 1810]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692aa7dd` | response-prompt | agent prompt: "Ask Essence Name" | `next` → New Block 27 |

### Block: New Block 27
**ID:** `68c075ec`  **Coords:** `[1314, 2013]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a964a` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68c075ec` | capture-v3 | capture user input → long_thought | `next` → New Block 28 |

### Block: New Block 31
**ID:** `68c07831`  **Coords:** `[1325, 2661]`  **Steps:** 4

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c2d5c3` | response-prompt | agent prompt: "Generate Category Question" | — |
| `68c2dc36` | set-v3 | exampleCategories = '<last_response> ' | — |
| `68c1e7f5` | set-v3 | examples = '6907624e353d04e3f7b4fbe3' | — |
| `68c1e8b4` | function | function: Show Buttons | `default` → New Block 32 |

### Block: New Block 28
**ID:** `68c07600`  **Coords:** `[1328, 2308]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c07600` | set-v3 | selectedEssence = '6907624e353d04e3f7b4fbdf' | — |
| `68c07686` | kb-search | kb-search: "Nome: <selectedEssence> " → final_chunks | `next` → New Block 94 |

### Block: Essence Follow Up
**ID:** `6899a3da`  **Coords:** `[1335, 810]`  **Steps:** 3

**Purpose:** Sends a follow-up message, sets example buttons, calls Show Buttons function. Loops back to Description Listening for more user input.

**Exits to:** Description Listening

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68a2fd05` | message | send static message | — |
| `68a2fbef` | set-v3 | examples = '6907624e353d04e3f7b4fbd5' | — |
| `68a2fbf4` | function | function: Show Buttons | `default` → Description Listening |

### Block: New Block 47
**ID:** `68fcfdb8`  **Coords:** `[1383, 4331]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6902745e` | response-prompt | agent prompt: "Non-NdC Perfume Name" | — |
| `695a9684` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68fcfdda` | capture-v3 | capture user input → last_utterance | `next` → New Block 90 |

### Block: New Block 90
**ID:** `6967c650`  **Coords:** `[1395, 4669]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c650` | set-v3 | pathInfoValue = '<last_utterance> ' | `next` → New Block 48 |

### Block: New Block 44
**ID:** `68fcf92b`  **Coords:** `[1404, 3719]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a967a` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68fcf966` | capture-v3 | capture user input → last_utterance | `next` → New Block 45 |

### Block: New Block 74
**ID:** `6944074d`  **Coords:** `[1608, -1267]`  **Steps:** 4

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a97ee` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `6944074d` | set-v3 | italian_labels = 'Nessuna Nota', english_labels = 'No Additional Info' | — |
| `6944074d` | component | call diagram: Show Lamguage Buttons | — |
| `6944074d` | condition-v3 | if final_label == "[{'text': ['Nessuna " | `else` → New Block 78, `if final_label=="[{'text': ['Nes"` → → Naming Ritual |

### Block: Show Suggestion Buttons
**ID:** `689080b3`  **Coords:** `[1633, 7]`  **Steps:** 1

**Purpose:** Shows name suggestion buttons using Show Buttons function.

**Exits to:** Save Name Reply

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `689080b3` | function | function: Show Buttons | `default` → Save Name Reply |

### Block: New Block 74
**ID:** `692aaff4`  **Coords:** `[1636, -550]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692aafb7` | set-v3 | italian_labels = 'Leggero,Moderato,Intenso', english_labels = 'Light,Moderate,Intense' | — |
| `692aafb7` | component | call diagram: Show Lamguage Buttons | — |
| `692aafb7` | condition-v3 | if final_label == "[{'text': ['Leggero'" AND final_label == "[{'text': ['Moderato" | `else` → Perfume Intensity, `if final_label=="[{'text': ['Leg"` → New Block 54 |

### Block: Description Listening
**ID:** `68879efb`  **Coords:** `[1720, 648]`  **Steps:** 2

**Purpose:** Enables user input (`userCanWrite = Math.random()`), captures utterance into `last_utterance`.

**Exits to:** Base Essence Validator

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a934d` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68879efb` | capture-v3 | capture user input → last_utterance | `next` → Base Essence Validator |

### Block: Base Essence Validator
**ID:** `68879a15`  **Coords:** `[1730, 902]`  **Steps:** 2

**Purpose:** Sets `enough_info` via agent response, then branches: if `enough_info == "avanti"` → Retireve Memory Info; if KB search needed → KB Search then JSON carousel (sequential sub-flow calls); else → Essence Follow Up (more questions).

**Exits to:** Retireve Memory Info, KB Search → JSON carousel pipeline, Essence Follow Up

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688a1951` | set-v3 | enough_info = '6907624e353d04e3f7b4fbf6' | — |
| `68879f1c` | condition-v3 | if enough_info == "[{'text': ['avanti']" | `cmdnar80h00m` → `6887a40a` (actions container), `if enough_info=="[{'text': ['ava"` → Retireve Memory Info, `else` → Essence Follow Up |
| `6887a40a` | component | *(in standalone actions container — step 1 of 2)* call diagram: KB Search (48-node) | → `6887a417` |
| `6887a417` | component | *(in standalone actions container — step 2 of 2)* call diagram: JSON list to carousel | → (continues flow) |

### Block: Retireve Memory Info
**ID:** `688f26b0`  **Coords:** `[1737, 1227]`  **Steps:** 2

**Purpose:** Stores `memory_description` and `pathInfoValue` from agent response, then routes to Get Essences.

**Exits to:** Get Essences

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f26b0` | set-v3 | memory_description = '6907624e353d04e3f7b4fbfa' | `next` → Get Essences |
| `6967c2fc` | set-v3 | pathInfoValue = '<memory_description> ' | `next` → Get Essences |

### Block: New Block 32
**ID:** `68c1e8cf`  **Coords:** `[1742, 2585]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a965b` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68c1e8cf` | capture-v3 | capture user input → exampleCategories | `next` → New Block 33 |

### Block: New Block 33
**ID:** `68c1e989`  **Coords:** `[1748, 2847]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c1e989` | kb-search | kb-search: "Categoria: <exampleCategories> " → kb_results | `next` → New Block 34 |
| `68c2d660` | set-v3 | long_thought = '6907624e353d04e3f7b4fbe5' | `next` → New Block 34 |

### Block: New Block 94
**ID:** `697dd0d1`  **Coords:** `[1848, 1584]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dd0d1` | response-prompt | agent prompt: "Essence Selector" | `next` → New Block 91 |

### Block: New Block 91
**ID:** `697dce43`  **Coords:** `[1859, 1763]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dce43` | function | function: Create Carousel | `68868eb92268` → New Block 93 |

### Block: New Block 93
**ID:** `697dcf55`  **Coords:** `[1863, 2066]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dcf55` | capture-v3 | capture user input → last_utterance | `next` → New Block 8 |

### Block: New Block 45
**ID:** `68fcf975`  **Coords:** `[1880, 3699]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68fcfb36` | set-v3 | chosen_fragrance = '6907624e353d04e3f7b4fc04' | — |
| `690271e3` | condition-v3 | if chosen_fragrance == "[{'text': ['none']}]" | `else` → New Block 89, `if chosen_fragrance=="[{'text': ['non"` → New Block 51 |

### Block: New Block 48
**ID:** `68fcff82`  **Coords:** `[1885, 4313]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68fcffa6` | api-v2 | HTTP POST: https://api.exa.ai/answer | `next` → Begin Essence Search |

### Block: New Block 8
**ID:** `697dce98`  **Coords:** `[1885, 2264]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dce98` | function | function: Post Process Essences | `6899c8830a2a` → Post-Process Selection |

### Block: New Block 89
**ID:** `6967c623`  **Coords:** `[1896, 3993]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c623` | set-v3 | pathInfoValue = '<chosen_fragrance> ' | `next` → New Block 51 |

### Block: New Block 51
**ID:** `69027205`  **Coords:** `[1948, 3564]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69027205` | response-prompt | agent prompt: "NdC Fragrance not found" | `next` → New Block 44 |

### Block: New Block 65
**ID:** `691b3ebc`  **Coords:** `[1995, 4655]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691b3ebc` | set-v3 | fragrance_notes = '{"testa": {"ribes nero", "pepe', target_gender = 'Uomo' | `next` → Begin Essence Search |

### Block: New Block 78
**ID:** `694407e5`  **Coords:** `[2071, -864]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `694407e5` | set-v3 | additionalInfo = '<last_utterance> ' | `next` → → Naming Ritual |

### Block: Save Name Reply
**ID:** `68908177`  **Coords:** `[2097, 2]`  **Steps:** 2

**Purpose:** Enables user input, captures perfume name into `last_utterance`. Routes to Finish Journey.

**Exits to:** Finish Journey

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a980d` | set-v3 | userCanWrite = "['Math.random()']" | — |
| `68908177` | capture-v3 | capture user input → last_utterance | `next` → Finish Journey |

### Block: New Block 34
**ID:** `68c1e9da`  **Coords:** `[2210, 2687]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c2d5e3` | response-prompt | agent prompt: "Extract Followup" | — |
| `68c1ea20` | set-v3 | examples = '6907624e353d04e3f7b4fbf5' | — |
| `68c1ea37` | function | function: Show Buttons | `default` → New Block 35 |

### Block: New Block 54
**ID:** `6909d176`  **Coords:** `[2212, -329]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6909d176` | set-v3 | perfume_intensity = '<last_utterance> ' | `next` → → Additional Notes |

### Block: New Block 35
**ID:** `68c1ea50`  **Coords:** `[2214, 3035]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c1ea50` | capture-v3 | capture user input → last_utterance | `next` → New Block 36 |

### Block: New Block 36
**ID:** `68c1ea6d`  **Coords:** `[2229, 3235]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c1ea6d` | set-v3 | essence_descriptions = '6907624e353d04e3f7b4fbf1' | `next` → New Block 37 |

### Block: Get Essences
**ID:** `688f2978`  **Coords:** `[2364, 460]`  **Steps:** 1

**Purpose:** Calls KB Search (48-node) sub-flow with the current query. Results drive essence carousel.

**Exits to:** Show Essences Carousel

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f2978` | component | call diagram: KB Search | `next` → Show Essences Carousel |

### Block: Show Essences Carousel
**ID:** `692731af`  **Coords:** `[2369, 625]`  **Steps:** 1

**Purpose:** Calls "JSON list to carousel with random image" to render essence chunks as a carousel.

**Exits to:** Analyze Selected Chunks

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f2980` | component | call diagram: JSON list to carousel with random image | `next` → Analyze Selected Chunks |

### Block: Post-Process Selection
**ID:** `697dce98`  **Coords:** `[2383, 1596]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dce98` | function | function: Process Selected Chunk | `6888dc6f28d8` → Add Essence to Selection |

### Block: Add Essence to Selection
**ID:** `697dce98`  **Coords:** `[2384, 1902]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dce98` | function | function: Add Essence to Selection | `default` → New Block 88 |

### Block: New Block 88
**ID:** `6967c382`  **Coords:** `[2396, 2094]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c382` | code | inline JS: essence = JSON.parse(selectedChunk)
essenceName = essence["N | `next` → New Block 87 |

### Block: New Block 87
**ID:** `6967c32e`  **Coords:** `[2399, 2400]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6967c32e` | set-v3 | pathInfoValue = '<essenceName> ' | `next` → → Get Essences |

### Block: Begin Essence Search
**ID:** `68fd01b8`  **Coords:** `[2406, 4331]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `692750e8` | response-prompt | agent prompt: "Perfume Notes" | — |
| `6916dc15` | set-v3 | perfume_description = '6916d96fef4c3b7b2c390072' | `next` → New Block 58 |

### Block: New Block 51
**ID:** `690271e4`  **Coords:** `[2515, 3539]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69026e22` | kb-search | kb-search: "Nome: <chosen_fragrance> " → kb_results | — |
| `68fcfa8a` | function | function: Post Process Essences | `6899c8830a2a` → New Block 101 |

### Block: New Block 46
**ID:** `68fcfc33`  **Coords:** `[2518, 3901]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68fcfc33` | function | function: Add Essence to Selection | `default` → → Get Essences |

### Block: Finish Journey
**ID:** `68908197`  **Coords:** `[2545, 15]`  **Steps:** 1

**Purpose:** Sets `perfumeName = last_utterance`. Routes to New Block 25 (Create generalInfo).

**Exits to:** New Block 25 (Create generalInfo)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6890819c` | set-v3 | perfumeName = '<last_utterance> ' | `next` → New Block 25 |

### Block: New Block 37
**ID:** `68c2d873`  **Coords:** `[2701, 2719]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c2d873` | function | function: Post Process Essences | `6899c8830a2a` → New Block 39 |

### Block: New Block 39
**ID:** `68c3191b`  **Coords:** `[2722, 3061]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c3191b` | response-prompt | agent prompt: "Essence Path Initial Description" | `next` → → Show Essences Carousel |

### Block: Analyze Selected Chunks
**ID:** `688f2b0c`  **Coords:** `[2856, 539]`  **Steps:** 1

**Purpose:** Routes based on `selectedChunksLength` and `enhancedEssence`: 4 essences without enhancement → Prompt 5th Essence; 4 with enhancement → New Block 55 (Acknowledge+Finish); else → Get Essences (loop).

**Exits to:** Prompt 5th Essence, New Block 55, Get Essences

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688f2b0c` | condition-v3 | if selectedChunksLength == "[{'text': ['4']}]" AND enhancedEssence == "[{'text': ['0']}]" / selectedChunksLength == "[{'text': ['4']}]" AND enhancedEssence == "[{'text': ['0']}]" | `else` → Get Essences, `if selectedChunksLength=="[{'text': ['4']"` → New Block 55 |

### Block: New Block 58
**ID:** `6916dbba`  **Coords:** `[2889, 4328]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6916dd10` | set-v3 | essence_query = '6916dbc2ef4c3b7b2c390075' | — |
| `6916dd41` | set-v3 | essence_query = '6916dcbaef4c3b7b2c390078' | `next` → New Block 59 |

### Block: New Block 101
**ID:** `698a345e`  **Coords:** `[3044, 3729]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `698a345e` | function | function: Process Selected Chunk | `6888dc6f28d8` → New Block 46 |

### Block: New Block 25
**ID:** `6893a723`  **Coords:** `[3148, 153]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6893a723` | function | function: Create generalInfo | `default` → New Block 83 |

### Block: New Block 39
**ID:** `68c2dccf`  **Coords:** `[3215, 2670]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68c2dccf` | message | send static message | `next` → (end flow) |

### Block: Prompt 5th Essence
**ID:** `688f2d95`  **Coords:** `[3355, 468]`  **Steps:** 5

**Purpose:** Acknowledges user selections, offers a 5th essence or "Avanti" (go on). Routes: Avanti → Amplify or Go On; Add essence → Get Essences (loop).

**Exits to:** Amplify or Go On, → Get Essences (goTo)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68b85c31` | response-prompt | agent prompt: "Acknowledge Selections" | — |
| `68b2e1c9` | response-prompt | agent prompt: "5th Essence or Amplify" | — |
| `690f7116` | set-v3 | italian_labels = 'Aggiungere,Avanti', english_labels = 'Add,Go On' | — |
| `690f7184` | component | call diagram: Show Lamguage Buttons | — |
| `690f719b` | condition-v3 | if final_label == "[{'text': ['Avanti']" / final_label == "[{'text': ['Aggiunge" | `if final_label=="[{'text': ['Agg"` → → Get Essences, `if final_label=="[{'text': ['Ava"` → Amplify or Go On |

### Block: New Block 55
**ID:** `690a2cf7`  **Coords:** `[3386, 1256]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690a2cf7` | response-prompt | agent prompt: "Acknowledge Selections" | `next` → Finish Perfume Creation |

### Block: New Block 59
**ID:** `6916dd6d`  **Coords:** `[3415, 4317]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6916dd6d` | kb-search | kb-search: "<essence_query> " → essences | — |
| `6916de41` | set-v3 | final_essence = '6916de4aef4c3b7b2c39007b' | `next` → New Block 66 |

### Block: New Block 73
**ID:** `691df96b`  **Coords:** `[3446, 4792]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691dfd6a` | set-v3 | query_feedback = '691dfd1be924945d63a48093' | `next` → New Block 58 |
| `6921f7af` | code | inline JS: failedIterationsParsed = Number(failedIterations)
failedIter | `next` → New Block 58 |

### Block: New Block 83
**ID:** `695a90ce`  **Coords:** `[3616, 148]`  **Steps:** 1

**Purpose:** Sends a static message and ends the flow (dead-end / fallback branch).

**Exits to:** (end flow)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `695a90ce` | message | send static message | `next` → (end flow) |

### Block: New Block 25
**ID:** `6893a874`  **Coords:** `[3689, -263]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6893a874` | set-v3 | generalInfo = '<preGeneralInfo> ' | `next` → (end flow) |

### Block: Amplify or Go On
**ID:** `690f8540`  **Coords:** `[3856, 466]`  **Steps:** 4

**Purpose:** Offers "Intensify" or "Same Intensity". Routes to New Block 74 (intensity sub-flow) or Finish Perfume Creation.

**Exits to:** New Block 74 (Intensify), Finish Perfume Creation (Same)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f8540` | response-prompt | agent prompt: "Amplify or Go On" | — |
| `690f858f` | set-v3 | italian_labels = 'Intensificare,Stessa Intensità', english_labels = 'Intensify,Same Intensity' | — |
| `690f85a6` | component | call diagram: Show Lamguage Buttons | — |
| `690f85b1` | condition-v3 | if final_label == "[{'text': ['Intensif" / final_label == "[{'text': ['Stessa I" | `if final_label=="[{'text': ['Int"` → New Block 74, `if final_label=="[{'text': ['Ste"` → Finish Perfume Creation |

### Block: New Block 66
**ID:** `691de4a8`  **Coords:** `[3887, 4309]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691de4a8` | set-v3 | final_essence = '691de4b2bdf249107782a154' | `next` → New Block 72 |

### Block: New Block 72
**ID:** `691df940`  **Coords:** `[3896, 4686]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691df940` | condition-v3 | if final_essence == "[{'text': ['none']}]" | `else` → New Block 68, `if final_essence=="[{'text': ['non"` → New Block 73 |

### Block: New Block 95
**ID:** `697dd5a4`  **Coords:** `[3902, 5143]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697dd5a4` | set-v3 | blacklistEssence = '<final_essence> ' | `next` → New Block 73 |

### Block: New Block 68
**ID:** `691de599`  **Coords:** `[4413, 4165]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691de599` | function | function: Post Process Essences | `6899c8830a2a` → New Block 69 |

### Block: New Block 69
**ID:** `691de59f`  **Coords:** `[4417, 4438]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691de59f` | function | function: Process Selected Chunk | `6888dc6f28d8` → New Block 81 |

### Block: New Block 74
**ID:** `693d8189`  **Coords:** `[4421, 418]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `693d85d6` | response-prompt | agent prompt: "Potenziare Categoria" | — |
| `693d8444` | set-v3 | categories = '693d81a4d708c2f74ae3b605' | — |
| `693d8467` | function | function: Show Buttons | `default` → New Block 75 |

### Block: New Block 74
**ID:** `69480d58`  **Coords:** `[4422, 4881]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69480d58` | set-v3 | italian_labels = 'Avanti,Sostituisci', english_labels = 'Go On,Replace' | — |
| `69480d58` | component | call diagram: Show Lamguage Buttons | — |
| `69480d58` | condition-v3 | if final_label == "[{'text': ['Avanti']" / final_label == "[{'text': ['Sostitui" | `if final_label=="[{'text': ['Sos"` → New Block 95, `if final_label=="[{'text': ['Ava"` → New Block 67, `else` → New Block 67 |

### Block: New Block 81
**ID:** `69480d10`  **Coords:** `[4425, 4709]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69762dbe` | response-prompt | agent prompt: "Fragrance Path Essence Prompter" | `next` → New Block 83 |

### Block: New Block 67
**ID:** `691de540`  **Coords:** `[4439, 5361]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691de540` | function | function: Add Essence to Selection | `default` → New Block 74 |

### Block: New Block 75
**ID:** `693d847d`  **Coords:** `[4442, 745]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `693d847d` | capture-v3 | capture user input → enhancedCategory | `next` → Finish Perfume Creation |

### Block: Prompt Enhance Essence
**ID:** `688f32ff`  **Coords:** `[4445, 971]`  **Steps:** 3

**Purpose:** Runs "Potenziare Essenza" agent, calls Select Essence sub-flow, sets `enhancedEssence`. Routes to Finish Perfume Creation.

**Exits to:** Finish Perfume Creation

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68b2e338` | response-prompt | agent prompt: "Potenziare Essenza" | — |
| `688f349c` | component | call diagram: Select Essence | — |
| `688f3581` | set-v3 | enhancedEssence = '<selectedEssence> ' | `next` → Finish Perfume Creation |

### Block: New Block 74
**ID:** `692752cd`  **Coords:** `[4445, 5533]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `691de659` | condition-v3 | if current_fragrance_essence == "[{'text': ['4']}]" | `else` → New Block 58, `if current_fragrance_essence=="[{'text': ['4']"` → New Block 73 |

### Block: Finish Perfume Creation
**ID:** `689082a2`  **Coords:** `[4887, 1309]`  **Steps:** 4

**Purpose:** Shows "Swap Essence or Keep Going" choice. "Modifica" → Essence edit sub-flow (New Block 72); "Avanti" → Keep Going → Perfume Intensity.

**Exits to:** Keep Going, New Block 72 (edit path)

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68b2e550` | response-prompt | agent prompt: "Swap Essence or Keep Going" | — |
| `690f7259` | set-v3 | italian_labels = 'Modifica,Avanti', english_labels = 'Edit,Go On' | — |
| `690f7282` | component | call diagram: Show Lamguage Buttons | — |
| `690f7294` | condition-v3 | if final_label == "[{'text': ['Modifica" / final_label == "[{'text': ['Avanti']" | `if final_label=="[{'text': ['Ava"` → Keep Going, `if final_label=="[{'text': ['Mod"` → New Block 72 |

### Block: New Block 73
**ID:** `691f57ab`  **Coords:** `[4911, 5592]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69272e75` | response-prompt | agent prompt: "Describe non-NdC perfume" | — |
| `697f844a` | function | function: Create Essence Buttons | `68b8aec1d930` → New Block 3 |

### Block: New Block 3
**ID:** `697f844a`  **Coords:** `[4922, 5957]`  **Steps:** 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `69272f04` | set-v3 | italian_labels = 'Concludi', english_labels = 'Finish' | — |
| `697f844a` | component | call diagram: Show Lamguage Buttons | — |
| `697f844a` | condition-v3 | if final_label == "[{'text': ['Annulla " AND final_label == "[{'text': ['Concludi" | `else` → Retrieve Selection, `if final_label=="[{'text': ['Ann"` → → Keep Going |

### Block: New Block 83
**ID:** `6948107e`  **Coords:** `[5024, 4767]`  **Steps:** 1

**Purpose:** Builds the essence carousel data structure. Routes to New Block 74 (carousel interaction).

**Exits to:** New Block 74

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6948107e` | function | function: Create Carousel | `68868eb92268` → New Block 74 |

### Block: Retrieve Selection
**ID:** `697f844a`  **Coords:** `[5451, 6276]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697f844a` | kb-search | kb-search: "Nome: <last_utterance> " → selectedEssence | `next` → New Block 4 |

### Block: New Block 72
**ID:** `69272f91`  **Coords:** `[5467, 1008]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a6ed` | set-v3 | italian_labels = 'Annulla Modifica', english_labels = 'Undo Edit' | `next` → Essence Select |

### Block: Keep Going
**ID:** `690fc6c4`  **Coords:** `[5468, 1630]`  **Steps:** 1

**Purpose:** Sets `fragrance_description` from agent response. Routes to → Perfume Intensity (goTo).

**Exits to:** → Perfume Intensity

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690fc6c4` | set-v3 | fragrance_description = '690fc6ccc77cdc8365e614ba' | `next` → → Perfume Intensity |

### Block: Essence Select
**ID:** `689082cc`  **Coords:** `[5479, 1284]`  **Steps:** 1

**Purpose:** Runs "Choose Essence To Remove" agent. Routes to Create Buttons.

**Exits to:** Create Buttons

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68b2e9c2` | response-prompt | agent prompt: "Choose Essence To Remove" | `next` → Create Buttons |

### Block: New Block 4
**ID:** `697f844a`  **Coords:** `[5920, 6222]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697f844a` | function | function: Post Process Essences | `6899c8830a2a` → New Block 5 |

### Block: Create Buttons
**ID:** `6918a612`  **Coords:** `[6050, 1142]`  **Steps:** 1

**Purpose:** Runs Create Essence Buttons function to display current essence choices. Routes to New Block 3.

**Exits to:** New Block 3

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a612` | function | function: Create Essence Buttons | `68b8aec1d930` → New Block 3 |

### Block: New Block 3
**ID:** `6918a6ed`  **Coords:** `[6057, 1429]`  **Steps:** 2

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a6ed` | component | call diagram: Show Lamguage Buttons | — |
| `6918a6ed` | condition-v3 | if final_label == "[{'text': ['Annulla " AND final_label == "[{'text': ['Concludi" | `else` → Retrieve Selection, `if final_label=="[{'text': ['Ann"` → → Finish Perfume Creation |

### Block: Retrieve Selection
**ID:** `6918a612`  **Coords:** `[6073, 1862]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a612` | kb-search | kb-search: "Nome: <last_utterance> " → selectedEssence | `next` → New Block 4 |

### Block: New Block 5
**ID:** `697f844a`  **Coords:** `[6436, 6219]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697f844a` | function | function: Process Selected Chunk | `6888dc6f28d8` → Essence Removal |

### Block: New Block 4
**ID:** `6918a612`  **Coords:** `[6661, 1864]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a612` | function | function: Post Process Essences | `6899c8830a2a` → New Block 5 |

### Block: Essence Removal
**ID:** `697f844a`  **Coords:** `[6950, 6215]`  **Steps:** 1

**Purpose:** Calls Remove Essence function to remove an essence from `selectedChunks`. Then jumps back to Get Essences.

**Exits to:** → Get Essences

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `697f844a` | function | function: Remove Essence | `68908cbc1764` → → Get Essences |

### Block: New Block 5
**ID:** `6918a612`  **Coords:** `[7143, 1871]`  **Steps:** 1

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a612` | function | function: Process Selected Chunk | `6888dc6f28d8` → Essence Removal |

### Block: Essence Removal
**ID:** `68908b05`  **Coords:** `[7622, 1871]`  **Steps:** 1

**Purpose:** Calls Remove Essence function to remove an essence from `selectedChunks`. Then jumps back to Get Essences.

**Exits to:** → Get Essences

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68908b05` | function | function: Remove Essence | `68908cbc1764` → → Get Essences |
