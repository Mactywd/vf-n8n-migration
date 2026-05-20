# Perfume Type Selector

**Total nodes:** 7  
**Role:** Presents a two-option choice (home use vs. personal gift) and writes the result to `perfume_type` (`"casa"` or `"personale"`).  
**Diagram type:** COMPONENT (registered as a standalone flow in the `flows` list)  
**Called from:** Not referenced as a component in any other diagram in the current build. Listed in the flows catalog — may be intended as a standalone entry point or pending integration into ROOT.  
**Returns to:** Caller implicitly after setting `perfume_type`

---

## Block: Type Choice

**Purpose:** Presents a two-button choice to the user (home perfume vs. personal perfume).  
**Entry point:** Yes — start node (`688fbdc47291a60006a6a959`) connects here.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688fbdfc78ae738a1964d8c6` | choice-v2 | Two-option button choice (button labels defined in app UI, not in raw JSON data). Port `cmdw3lsrl00p1287k4nzzt93m` = home choice; port `cmdw3lyu300qo287k4zvx1qis` = personal choice | `cmdw3lsrl00p1287k4nzzt93m` → `Set to Home`; `cmdw3lyu300qo287k4zvx1qis` → `Set to Personal` |

---

## Block: Set to Home

**Purpose:** Sets `perfume_type` = `"casa"` (home use).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688fbe1c78ae738a1964d8d1` | set-v3 | `perfume_type` = `"casa"` | next → (exits component) |

---

## Block: Set to Personal

**Purpose:** Sets `perfume_type` = `"personale"` (personal gift / wearable).

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688fbe3378ae738a1964d8db` | set-v3 | `perfume_type` = `"personale"` | next → (exits component) |

---

## Start Node

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `688fbdc47291a60006a6a959` | start | Entry point | next → `Type Choice` |

---

## Flow Summary

```
START → Type Choice (choice-v2, 2 buttons)
    [home button]     → Set to Home     → perfume_type = "casa"      → (return to caller)
    [personal button] → Set to Personal → perfume_type = "personale" → (return to caller)
```

> **Migration note (n8n):** This is a minimal two-branch component. In n8n it maps to a Chat Message trigger (or button-click webhook) followed by an If node with two Set nodes. Since it is currently not called from ROOT, verify whether it should be inserted before the "Get Essences" block or somewhere else in the main flow during migration.
