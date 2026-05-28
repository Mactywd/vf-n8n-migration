# Target Selector

**Total nodes:** 12  
**Role:** Agent-driven masculine / feminine / universal selection — presents localised gender-target buttons via the Show Lamguage Buttons component, captures the user's choice, then routes to one of three SET nodes to write `target_gender` = `"Uomo"`, `"Donna"`, or `"Unisex"`.  
**Diagram type:** COMPONENT (reusable sub-flow)  
**Called from:** ROOT > `Intro + Gender Select` block  
**Returns to:** Caller (ROOT) implicitly after setting `target_gender`

---

## Block: New Block 5

**Purpose:** Sets the localised button labels then invokes the Show Lamguage Buttons component to present them.  
**Entry point:** Yes — start node (`68869bb647d98100077d7839`) connects here.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f6451c501166d01775ff2` | set-v3 | `italian_labels` = `"Per Lui,Per Lei,Per Entrambi"`; `english_labels` = `"For Him,For Her,For Both"` | next → (sequential) |
| `690f6390c501166d01775bf8` | component | Calls **Show Lamguage Buttons** diagram (`690f5cea514a87470772f220`) | next → `New Block 7` (condition) |

---

## Block: New Block 7 (condition)

**Purpose:** Routes to the correct `target_gender` setter based on which button the user pressed.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f64bbc501166d01776008` | condition-v3 | Checks `final_label`: branch 1 = "Per Lui" / "For Him"; branch 2 = "Per Lei" / "For Her"; branch 3 = "Per Entrambi" / "For Both" | `cmhqgdcd304s72881p8zcklxh` → `New Block 7` (Uomo); `cmhqgdmvj04yy2881mgkkuofr` → `New Block 8` (Donna); `cmhqgdvkl05672881n19uqb3q` → `New Block 9` (Unisex); else → (none) |

---

## Block: New Block 7 (set Uomo)

**Purpose:** Sets `target_gender` = `"Uomo"`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f64fec501166d01776017` | set-v3 | `target_gender` = `"Uomo"` | next → (exits component) |

---

## Block: New Block 8 (set Donna)

**Purpose:** Sets `target_gender` = `"Donna"`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f6516c501166d01776021` | set-v3 | `target_gender` = `"Donna"` | next → (exits component) |

---

## Block: New Block 9 (set Unisex)

**Purpose:** Sets `target_gender` = `"Unisex"`.

### Nodes

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `690f6530c501166d0177602b` | set-v3 | `target_gender` = `"Unisex"` | next → (exits component) |

---

## Start Node

| node_id | type | config summary | ports → next |
|---------|------|----------------|--------------|
| `68869bb647d98100077d7839` | start | Entry point | next → `New Block 5` |

---

## Flow Summary

```
START → New Block 5
  SET italian_labels / english_labels
  → Show Lamguage Buttons (component)
    → New Block 7 (condition on final_label)
        "Per Lui" / "For Him"     → SET target_gender = "Uomo"   → (return to ROOT)
        "Per Lei" / "For Her"     → SET target_gender = "Donna"  → (return to ROOT)
        "Per Entrambi" / "For Both" → SET target_gender = "Unisex" → (return to ROOT)
```
