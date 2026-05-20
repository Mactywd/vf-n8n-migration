# Session Helper Workflows

**File**: `docs/superpowers/plans/setup/02-session-workflows.md`  
**Scope**: Two reusable n8n sub-workflows that every other Alchimista workflow calls to read and write session state from Supabase.

---

## Overview

Because every n8n workflow execution is stateless, all conversational state lives in the `alchimista_sessions` Supabase table (see `02-session-schema.sql`). Rather than duplicating Supabase logic in every workflow, we centralise it in two tiny helper workflows:

| Workflow | Trigger type | Purpose |
|----------|--------------|---------|
| `session-read` | Execute Workflow | Load full session state, merge with defaults |
| `session-write` | Execute Workflow | Partial-update (upsert) session state |

Both are called via the **Execute Workflow** node from every other workflow. They accept their inputs through `$json` (the data passed by the calling workflow) and return structured JSON outputs.

---

## Workflow 1: `session-read`

### Purpose

Given a `session_id`, fetch the matching row from Supabase and return an enriched session object. If the session does not exist yet it is created on first read (the upsert inside the schema guarantees a row always exists after the first call).

### Trigger

**Node type**: `Execute Workflow Trigger`  
**Name**: `On Call`

Expected input object from the calling workflow:
```json
{
  "session_id": "sess-abc123"
}
```

### Node list

| # | Name | Type | Key configuration |
|---|------|------|-------------------|
| 1 | `On Call` | Execute Workflow Trigger | Receives `{ session_id }` |
| 2 | `Validate Input` | Code (JS) | Throws if `session_id` is missing or empty |
| 3 | `Fetch Session` | HTTP Request | `POST /rest/v1/rpc/upsert_session` on Supabase with `p_session_id` only (no updates) — creates the row if it does not exist and returns the current row |
| 4 | `Merge Defaults` | Code (JS) | Deep-merges the DB row with hardcoded defaults for every variable (see defaults table below) |
| 5 | `Return Session` | Set | Maps the merged object to the output under key `session` |

### Node 2 — Validate Input (Code)

```javascript
const sessionId = $input.first().json.session_id;
if (!sessionId || typeof sessionId !== 'string' || sessionId.trim() === '') {
  throw new Error('session-read: session_id is required');
}
return [{ json: { session_id: sessionId.trim() } }];
```

### Node 3 — Fetch Session (HTTP Request)

| Field | Value |
|-------|-------|
| Method | `POST` |
| URL | `{{ $env.SUPABASE_URL }}/rest/v1/rpc/upsert_session` |
| Authentication | Header Auth — `apikey: {{ $env.SUPABASE_SERVICE_KEY }}` + `Authorization: Bearer {{ $env.SUPABASE_SERVICE_KEY }}` |
| Body (JSON) | `{ "p_session_id": "{{ $json.session_id }}", "p_columns": {}, "p_state": {} }` |
| Headers | `Content-Type: application/json`, `Prefer: return=representation` |

The Supabase `upsert_session` function inserts if absent and returns the full row, so this is both a "get or create" and a passthrough if the session already exists.

### Node 4 — Merge Defaults (Code)

```javascript
const row = $input.first().json;

// Default values for every named column (mirrors Voiceflow defaults)
const COLUMN_DEFAULTS = {
  chosen_path:          null,
  conversation_state:   null,
  target_gender:        'Uomo',
  perfume_type:         null,
  default_language:     '',
  perfume_memory:       null,
  chosen_fragrance:     null,
  fragrance_description:null,
  fragrance_notes:      null,
  user_essence:         null,
  qna_list:             '',
  memory_description:   null,
  enough_info:          false,
  selected_chunks:      [],
  blacklist_essences:   [],
  perfume_name:         null,
  name_suggestions:     null,
  should_save_name:     null,
  perfume_description:  null,
  perfume_intensity:    null,
  general_info:         null,
};

// Default values for state JSONB keys
const STATE_DEFAULTS = {
  current_essence_index:    0,
  failed_iterations:        0,
  bypass_kbsearch_chunks:   false,
  user_can_write:           true,
  must_choose:              false,
  is_selection_valid:       null,
  sessions_count:           1,
};

// Merge: DB value wins if non-null, otherwise use default
const columns = {};
for (const [k, def] of Object.entries(COLUMN_DEFAULTS)) {
  columns[k] = row[k] !== undefined && row[k] !== null ? row[k] : def;
}

const dbState = row.state || {};
const state = { ...STATE_DEFAULTS, ...dbState };

return [{
  json: {
    session_id: row.session_id,
    created_at: row.created_at,
    updated_at: row.updated_at,
    ...columns,
    state,
  }
}];
```

### Node 5 — Return Session (Set)

| Output key | Value |
|------------|-------|
| `session` | `{{ $json }}` (the full merged object from Node 4) |

### Output contract

The calling workflow receives:
```json
{
  "session": {
    "session_id": "sess-abc123",
    "created_at": "2026-05-20T10:00:00Z",
    "updated_at": "2026-05-20T10:05:00Z",
    "chosen_path": "memory",
    "target_gender": "Donna",
    "qna_list": "Q: ...\nA: ...\n",
    "enough_info": false,
    "selected_chunks": [],
    "blacklist_essences": [],
    "state": {
      "current_essence_index": 0,
      "failed_iterations": 0,
      ...
    },
    ...
  }
}
```

---

## Workflow 2: `session-write`

### Purpose

Perform a partial upsert on a session: only the keys present in the `updates` payload are written. Existing keys not mentioned in `updates` are left unchanged (the SQL `upsert_session` function handles the merge).

### Trigger

**Node type**: `Execute Workflow Trigger`  
**Name**: `On Call`

Expected input object from the calling workflow:
```json
{
  "session_id": "sess-abc123",
  "updates": {
    "columns": {
      "target_gender": "Donna",
      "enough_info": true
    },
    "state": {
      "current_essence_index": 2,
      "failed_iterations": 0
    }
  }
}
```

- `columns` → maps to the `p_columns` argument of `upsert_session`
- `state` → maps to the `p_state` argument (deep-merged into the JSONB `state` column)

Both `columns` and `state` are optional; omit either if there is nothing to update in that group.

### Node list

| # | Name | Type | Key configuration |
|---|------|------|-------------------|
| 1 | `On Call` | Execute Workflow Trigger | Receives `{ session_id, updates }` |
| 2 | `Validate Input` | Code (JS) | Throws if `session_id` or `updates` are missing |
| 3 | `Build Payload` | Code (JS) | Constructs the RPC payload; serialises JSONB arrays/objects correctly |
| 4 | `Upsert Session` | HTTP Request | `POST /rest/v1/rpc/upsert_session` |
| 5 | `Return Confirmation` | Set | Returns `{ success: true, session_id, updated_at }` |

### Node 2 — Validate Input (Code)

```javascript
const { session_id, updates } = $input.first().json;
if (!session_id) throw new Error('session-write: session_id is required');
if (!updates || typeof updates !== 'object') {
  throw new Error('session-write: updates object is required');
}
return [{ json: { session_id, updates } }];
```

### Node 3 — Build Payload (Code)

```javascript
const { session_id, updates } = $input.first().json;

const payload = {
  p_session_id: session_id,
  p_columns:    updates.columns ?? {},
  p_state:      updates.state   ?? {},
};

// Supabase RPC expects JSONB arrays/objects as actual JSON, not strings
// n8n serialises the body automatically — no extra work needed here.

return [{ json: payload }];
```

### Node 4 — Upsert Session (HTTP Request)

| Field | Value |
|-------|-------|
| Method | `POST` |
| URL | `{{ $env.SUPABASE_URL }}/rest/v1/rpc/upsert_session` |
| Authentication | Header Auth — `apikey: {{ $env.SUPABASE_SERVICE_KEY }}` + `Authorization: Bearer {{ $env.SUPABASE_SERVICE_KEY }}` |
| Body (JSON) | `{{ $json }}` (full payload from Node 3) |
| Headers | `Content-Type: application/json`, `Prefer: return=representation` |

### Node 5 — Return Confirmation (Set)

```javascript
// Extract the returned row to surface updated_at
const row = $input.first().json;
return [{
  json: {
    success:    true,
    session_id: row.session_id,
    updated_at: row.updated_at,
  }
}];
```

### Output contract

```json
{
  "success": true,
  "session_id": "sess-abc123",
  "updated_at": "2026-05-20T10:07:32Z"
}
```

---

## How calling workflows use these helpers

Every main workflow (e.g. `orchestrator`, `memory-extraction`, `essence-selection`) follows this pattern at the start of each execution:

```
Chat Trigger
    ↓
Extract session_id from trigger payload
    ↓
Execute Workflow: session-read  ←─── returns full session object
    ↓
... workflow logic using {{ $('session-read').item.json.session }}
    ↓
Execute Workflow: session-write  ←─── partial update with changed vars
    ↓
Return response to user
```

### Accessing session data in subsequent nodes

After calling `session-read`, all session variables are available as:

```
{{ $('session-read').item.json.session.target_gender }}
{{ $('session-read').item.json.session.selected_chunks }}
{{ $('session-read').item.json.session.state.current_essence_index }}
```

### Writing back at end of turn

Before returning the response, call `session-write` with only the variables that changed in the current turn:

```json
{
  "session_id": "{{ $('Extract session_id').item.json.session_id }}",
  "updates": {
    "columns": {
      "enough_info": true,
      "qna_list": "{{ $('Memory Agent').item.json.updated_qna_list }}"
    },
    "state": {
      "current_essence_index": 3
    }
  }
}
```

---

## Environment variables required

Both workflows rely on two n8n environment variables (set in n8n instance settings):

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Full project URL, e.g. `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Service-role API key (bypasses RLS, never expose to frontend) |

---

## Error handling

Both workflows should have an **Error Trigger** workflow set at the instance level, or each node should have the `On Error` setting pointing to a **Stop and Error** node that:
1. Logs the error to a Supabase `alchimista_errors` table (optional, future sprint)
2. Returns a structured error response so the caller can surface a graceful message to the user

---

## Variable classification reference

### Dedicated columns (survive across turns, drive branching)

`chosen_path`, `conversation_state`, `target_gender`, `perfume_type`, `default_language`, `perfume_memory`, `chosen_fragrance`, `fragrance_description`, `fragrance_notes`, `user_essence`, `qna_list`, `memory_description`, `enough_info`, `selected_chunks`, `blacklist_essences`, `perfume_name`, `name_suggestions`, `should_save_name`, `perfume_description`, `perfume_intensity`, `general_info`

### JSONB `state` column (pipeline intermediates, complex or frequently changing)

`kb_results`, `parsed_chunks`, `final_chunks`, `final_essences`, `current_essence_index`, `current_essence`, `essences`, `carousel_data`, `carousel_ids`, `essence_descriptions`, `additional_info`, `enhanced_category`, `categories`, `chosen_category`, `enhance_essence`, `bypass_kbsearch_chunks`, `failed_iterations`, `pre_kb_thought`, `fast_thought`, `long_thought`, `path_info_field`, `path_info_value`, `pre_general_info`, `user_can_write`, `must_choose`, `is_selection_valid`, `selection_id`, `selection_name`, `final_essence`, `current_fragrance_essence`, `usecase_info`, `example_categories`, `examples`, `user_query`, `essence_query`, `essence_name`, `categoria_followup`, `sessions_count`

### Excluded (system constants or pure scratch)

`api_key`, `document_id`, `exa_api`, `perfumes_available`, `tone_of_voice`, `essences_per_carousel` — initialised as Set nodes at workflow start, never persisted to DB.

`temp_variable`, `query_feedback` (duplicate), `buttons`, `card_desc`, `card_image`, `card_title`, `carouselData` (transient render artefacts), `italian_labels`, `english_labels`, `final_label`, `validation_output`, `error_message` — ephemeral within a single turn, no cross-turn value.

Voiceflow system variables (`user_id`, `last_utterance`, `vf_memory`, etc.) — replaced by n8n-native equivalents, not stored in this table.
