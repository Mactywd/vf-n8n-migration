# Show Language Buttons

**Total nodes:** 9  
**Role:** Language-aware button rendering component — takes `italian_labels` and `english_labels` arrays, picks the correct set based on `default_language`, renders the buttons to the user, captures their selection, then translates an Italian label back to its English equivalent (writing `final_label`) so downstream conditions work uniformly in English.  
**Diagram type:** COMPONENT (Voiceflow internal name: "Show Lamguage Buttons" — note the typo in the source)  
**Called from:**
- ROOT > `New Block 56`
- ROOT > `Prompt 5th Essence`
- ROOT > `Finish Perfume Creation`
- ROOT > `Fragrance Path Intro`
- ROOT > `Amplify or Go On`
- ROOT > `New Block 3` (×2 calls)
- ROOT > `New Block 74` (×4 calls)
- Target Selector > `New Block 5`
- JSON list to carousel > `New Block 74`  
**Returns to:** Caller implicitly after writing `final_label`

---

## Block: New Block 1

**Purpose:** Calls **Show Languaged Buttons** function to render the localised button set.  
**Entry point:** Yes — start node (`690f5cea437422000760a8be`) connects here.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f601ec501166d01775a02` | function | **Show Languaged Buttons** (fnID `690f603f6076dd72b3b07e37`) — inputs: `default_language`, `english_labels`, `italian_labels`; renders the correct button set | default → `New Block 2` (capture) |

---

## Block: New Block 2

**Purpose:** Waits for the user to press one of the rendered buttons.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f628fc501166d01775a0d` | capture-v3 | Captures user reply → `last_utterance` | next → `New Block 3` (Find Italian Choice) |

---

## Block: New Block 3

**Purpose:** Calls **Find Italian Choice** function to resolve `last_utterance` to a canonical English `final_label`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f62abc501166d01775a18` | function | **Find Italian Choice** (fnID `690f62b96076dd72b3b07ee2`) — inputs: `last_utterance`, `english_labels`, `italian_labels`; output: `final_label` | port (matched) → (exits component — `final_label` is set); port `6918a65c86853c311995b07d` → `New Block 4` (fallback) |

---

## Block: New Block 4

**Purpose:** Fallback — sets `final_label` = `"other"` if the user's input did not match any known button label.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `6918a6c77b5346be1f7fbe44` | set-v3 | `final_label` = `"other"` | next → (exits component) |

---

## Start Node

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f5cea437422000760a8be` | start | Entry point | next → `New Block 1` |

---

## Flow Summary

```
START → New Block 1 (Show Languaged Buttons fn — renders italian or english buttons)
  → New Block 2 (capture last_utterance)
    → New Block 3 (Find Italian Choice fn)
        [matched label]   → final_label = <canonical English value> → (return to caller)
        [unmatched label] → New Block 4 → final_label = "other"    → (return to caller)
```

## Key Variables

| variable | direction | description |
|----------|-----------|-------------|
| `italian_labels` | input | Comma-separated Italian button labels (set by caller) |
| `english_labels` | input | Comma-separated English button labels (set by caller) |
| `default_language` | input (global) | `"italian"` or `"english"` — selects which label set to display |
| `last_utterance` | output (global) | Raw user selection captured by Voiceflow |
| `final_label` | output | Canonical English value of the user's selection (used by callers in conditions) |

> **Migration note (n8n):** This component is called from 17 places in ROOT and sub-diagrams. In n8n it should become a reusable sub-workflow that accepts `italian_labels`, `english_labels`, and `default_language` as inputs, returns `final_label`. The language-selection logic (Show Languaged Buttons function) and Italian→English translation (Find Italian Choice function) both map to Code nodes. The capture step maps to a Chat Message trigger / wait-for-webhook.
