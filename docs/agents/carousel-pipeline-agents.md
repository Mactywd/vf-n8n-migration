## Carousel Pipeline Agents

These five agents live in the **"JSON list to carousel with random image"** diagram (Voiceflow diagram ID: `6885f3a4ad9cfa0007921fac`, 36 nodes). They form a sequential pipeline that takes a JSON list of essence objects, validates the structure, assigns random images to each item, and outputs a carousel-ready data structure.

All five agents use **claude-4-sonnet** (Claude Sonnet 4) at temperature 0.3, max tokens 500.

---

### Pipeline Overview

```
Input: JSON list (final_essences / final_chunks)
         ↓
[1] Clarify and confirm JSON list structure
         ├── List structure clear ──────────────────────┐
         └── List structure unclear or invalid ──→ [4] Request valid JSON list structure
                                                        ↓
                                                   (user provides corrected list → loops back to [1])
         ↓ (from "List structure clear")
[2] Select random image per carousel item
         ├── Images selected successfully ─────────────┐
         └── No images available for an item ──→ [5] Handle missing images in list items
                                                        ↓
                                                   (user updates imageURLs → loops back to [2])
         ↓ (from "Images selected successfully")
[3] Generate carousel display model
         └── Carousel successfully created ──→ carouselData variable → display to user
```

The three "happy path" agents are the core pipeline (1 → 2 → 3). Agents 4 and 5 handle error cases.

---

### Agent 1 — Clarify and confirm JSON list structure

**Voiceflow ID:** `6885f3a4ad9cfa0007921fa0`
**Model:** claude-4-sonnet
**Temperature:** 0.3
**Max tokens:** 500
**Reads variables:** `final_chunks` or `final_essences` (the JSON list to validate)
**Writes variables:** none directly

#### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| List structure clear | JSON list matches the expected schema (items with `name`, `content`, `imageURLs` fields) | Agent 2: Select random image per carousel item |
| List structure unclear or invalid | JSON is malformed, missing required fields, or ambiguous | Agent 4: Request valid JSON list structure |

#### System Prompt
```
Check if the provided JSON list matches the specified structure. If there is ambiguity or a mismatch in the structure, ask the user for clarification or a corrected sample. Proceed to rendering only if the JSON is confirmed to match.
```

---

### Agent 2 — Select random image per carousel item

**Voiceflow ID:** `6885f3a4ad9cfa0007921fa1`
**Model:** claude-4-sonnet
**Temperature:** 0.3
**Max tokens:** 500
**Reads variables:** validated JSON list (output from Agent 1)
**Writes variables:** internal image selection mapping (passed to Agent 3 via conversation context)

#### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| Images selected successfully | All items have at least one entry in their `imageURLs` array | Agent 3: Generate carousel display model |
| No images available for an item | One or more items have an empty `imageURLs` array | Agent 5: Handle missing images in list items |

#### System Prompt
```
For each item in the JSON list, select one image at random from the imageURLs array and associate it with the item. Keep a mapping of the selected image for each carousel item.
```

---

### Agent 3 — Generate carousel display model

**Voiceflow ID:** `6885f3a4ad9cfa0007921fa2`
**Model:** claude-4-sonnet
**Temperature:** 0.3
**Max tokens:** 500
**Reads variables:** validated JSON list + image selection mapping from Agent 2
**Writes variables:** `carouselData` (populated by downstream Set node from agent output)

#### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| Carousel successfully created | Carousel data structure assembled successfully | Exit → `carouselData` variable written → carousel displayed to user |

#### System Prompt
```
Create the carousel data structure. For each item: use the selected random image as the display image, set the name field as the title, and the content field as the subtitle. Do not include the description or type fields. Ensure the output format is suitable for the intended carousel rendering system.
```

---

### Agent 4 — Request valid JSON list structure (Error Handler)

**Voiceflow ID:** `6885f3a4ad9cfa0007921fa3`
**Model:** claude-4-sonnet
**Temperature:** 0.3
**Max tokens:** 500
**Reads variables:** none
**Writes variables:** none

#### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| User will provide corrected list | User acknowledges and provides a corrected JSON | Loop back to Agent 1 |

#### System Prompt
```
Inform the user that the provided input JSON list structure is invalid, ambiguous, or incomplete. Ask for a valid, well-structured JSON list with the specified fields.
```

---

### Agent 5 — Handle missing images in list items (Error Handler)

**Voiceflow ID:** `6885f3a4ad9cfa0007921fa4`
**Model:** claude-4-sonnet
**Temperature:** 0.3
**Max tokens:** 500
**Reads variables:** none
**Writes variables:** none

#### Output Paths
| Path name | Condition | Routes to |
|-----------|-----------|-----------|
| User will update imageURLs | User acknowledges and updates the imageURLs arrays | Loop back to Agent 2 |

#### System Prompt
```
Inform the user that one or more items in the JSON list do not have any images in the imageURLs array, and that a carousel cannot be created without images for all items. Request the user to add at least one image URL to each list item.
```

---

### n8n Migration Notes

**Important:** In n8n, this entire pipeline should be a **Code node**, not five separate AI Agent nodes. The logic is deterministic data transformation — only the random image selection and data structure assembly need any intelligence, and those can be implemented cleanly in JavaScript:

```javascript
// Pseudocode for a single Code node replacing all 5 carousel agents
const items = JSON.parse(finalChunks);

// Validate structure (Agent 1 logic)
for (const item of items) {
  if (!item.name || !item.content || !Array.isArray(item.imageURLs)) {
    throw new Error('Invalid JSON list structure: missing required fields');
  }
  if (item.imageURLs.length === 0) {
    throw new Error(`Item "${item.name}" has no imageURLs`);
  }
}

// Select random image per item (Agent 2 logic)
// Build carousel data model (Agent 3 logic)
const carouselData = items.map(item => ({
  imageUrl: item.imageURLs[Math.floor(Math.random() * item.imageURLs.length)],
  title: item.name,
  subtitle: item.content,
  id: item.id
}));

return { carouselData: JSON.stringify(carouselData) };
```

- The two error-handling agents (4 and 5) become `throw` statements in the Code node, with n8n error handling routing to a **Send Message node** that notifies the user
- `carouselData` → stored in n8n workflow variable, then rendered via the chat output node
- `carouselIDs` → parallel array of essence IDs extracted alongside carouselData, used to map user selection back to the KB chunk
- The diagram also contains `Create Essence Carousel` and `Create Carousel` JavaScript function nodes — those are the actual carousel-building logic in the current flow; the AI agents above are from the "Old Layout" sub-workflow and may be legacy
