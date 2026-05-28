# Phase 2: Utility Sub-Workflows — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and test the 5 reusable sub-workflows that ROOT will call on every turn.

**Architecture:** Each sub-workflow is an n8n workflow with an Execute Workflow Trigger, a clear input/output contract, and is tested independently before ROOT is built.

**Tech Stack:** n8n, PostgreSQL (Sessions DB credential), Qdrant (via HTTP), OpenRouter (AI Agent)

**Depends on:** Phase 0 (credentials configured), Phase 1 (Qdrant has data)  
**Required by:** Phase 3 (ROOT workflow calls all of these)

---

## Reference: n8n API commands

```bash
N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwNzQ2M2JlNy1jZmE1LTQzNTctYTNlOS0wMjE0NmMyYTZhMWEiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzc5NTI5MzY0fQ.3iX6kwwSE5KJOErF2mahMtUOQ5b5-m9_aCgO8dY4uzM"
N8N_BASE_URL="https://n8n.mattiagirellini.com"
```

---

## Task 1: session-read sub-workflow

**Contract:**
- Input: `{ "session_id": "abc-123" }`
- Output: full session state JSONB (merged with defaults if new session)

- [ ] **Step 1: Update the existing placeholder workflow**

The `session-read` workflow already exists (ID: `dUbkKodJGecb8x1v`). Fetch its current state:

```bash
curl -s "$N8N_BASE_URL/api/v1/workflows/dUbkKodJGecb8x1v" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" | python3 -m json.tool > /tmp/session-read-current.json
```

- [ ] **Step 2: Build the workflow node structure**

The workflow has 3 nodes:

**Node 1 — Execute Workflow Trigger** (already exists)
- Type: `n8n-nodes-base.executeWorkflowTrigger`
- No configuration needed

**Node 2 — Load or Create Session** (Postgres node)
- Type: `n8n-nodes-base.postgres`
- Credential: `Sessions DB`
- Operation: Execute Query
- Query:
```sql
INSERT INTO sessions (id, state)
VALUES ('{{ $json.session_id }}', '{}')
ON CONFLICT (id) DO NOTHING;
SELECT state FROM sessions WHERE id = '{{ $json.session_id }}';
```

**Node 3 — Merge Defaults** (Code node)
- Type: `n8n-nodes-base.code`
- Code:
```javascript
const DEFAULT_STATE = {
  current_step: "init",
  default_language: "it",
  target_gender: null,
  perfume_type: null,
  chosenPath: null,
  perfume_memory: null,
  selectedChunks: [],
  blacklistEssences: [],
  essences_per_carousel: 4,
  currentEssenceIndex: 0,
  final_essences: null,
  qna_list: "",
  generalInfo: null,
  perfumeName: null,
  tone_of_voice: "Speak as L'Alchimista del Chianti. Use mystical, poetic, sensory language. Ancient poet meets fragrance mystic.",
  enough_info: false,
  additionalInfo: "none"
};

const dbState = $input.first().json.state || {};
const merged = { ...DEFAULT_STATE, ...dbState };
return [{ json: { session_id: $('Execute Workflow Trigger').first().json.session_id, ...merged } }];
```

- [ ] **Step 3: Update the workflow via API**

Save the updated workflow JSON to `workflows/session-read.json` and deploy:

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/dUbkKodJGecb8x1v" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/session-read.json | python3 -m json.tool
```

- [ ] **Step 4: Test — new session**

In n8n test mode, run the workflow with input:
```json
{ "session_id": "test-phase2-001" }
```

Expected output: full state object with `current_step: "init"` and all defaults.

- [ ] **Step 5: Test — existing session**

First, insert a session with a non-default state:
```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "INSERT INTO sessions (id, state) VALUES ('test-phase2-002', '{\"current_step\": \"waiting_target_gender\", \"default_language\": \"it\"}');"
```

Run the workflow with `{ "session_id": "test-phase2-002" }`.

Expected output: state with `current_step: "waiting_target_gender"` (loaded from DB, not overwritten by defaults).

- [ ] **Step 6: Clean up test data**

```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "DELETE FROM sessions WHERE id IN ('test-phase2-001', 'test-phase2-002');"
```

---

## Task 2: session-write sub-workflow

**Contract:**
- Input: `{ "session_id": "abc-123", "updates": { "current_step": "waiting_target_gender", "target_gender": "Donna" } }`
- Output: `{ "ok": true }`

- [ ] **Step 1: Update the existing placeholder (ID: `q5nYFOV5vEgebBz8`)**

The workflow has 2 nodes:

**Node 1 — Execute Workflow Trigger** (already exists)

**Node 2 — Upsert Session** (Postgres node)
- Operation: Execute Query
- Query:
```sql
INSERT INTO sessions (id, state, updated_at)
VALUES (
  '{{ $json.session_id }}',
  '{{ JSON.stringify($json.updates) }}'::jsonb,
  now()
)
ON CONFLICT (id) DO UPDATE
SET state = sessions.state || '{{ JSON.stringify($json.updates) }}'::jsonb,
    updated_at = now();
```

**Node 3 — Return OK** (Set node)
- Field: `ok` = `true`

- [ ] **Step 2: Deploy via API**

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/q5nYFOV5vEgebBz8" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/session-write.json | python3 -m json.tool
```

- [ ] **Step 3: Test — write and read back**

Run with:
```json
{
  "session_id": "test-write-001",
  "updates": { "current_step": "waiting_sorting_path", "target_gender": "Donna" }
}
```

Then verify in Postgres:
```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "SELECT state FROM sessions WHERE id = 'test-write-001';"
```

Expected: `{"current_step": "waiting_sorting_path", "target_gender": "Donna"}`

- [ ] **Step 4: Test — partial update merges correctly**

Run session-write again with:
```json
{
  "session_id": "test-write-001",
  "updates": { "perfume_type": "personal" }
}
```

Expected state in DB: `{"current_step": "waiting_sorting_path", "target_gender": "Donna", "perfume_type": "personal"}` — previous fields preserved.

- [ ] **Step 5: Clean up**

```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "DELETE FROM sessions WHERE id = 'test-write-001';"
```

---

## Task 3: kb-search sub-workflow

**Contract:**
- Input: `{ "qna_list": "...", "perfume_memory": "...", "blacklistEssences": [], "essences_per_carousel": 4, "default_language": "it" }`
- Output: `{ "chunks": [ { "nome": "...", "categoria": "...", "contenuto_it": "...", ... } ] }`

- [ ] **Step 1: Build the workflow**

Nodes:

**Node 1 — Execute Workflow Trigger**

**Node 2 — KB Search Agent** (AI Agent node)
- Model: OpenRouter (via credential)
- Model name: `anthropic/claude-3.5-haiku` (fast and capable)
- System prompt:
```
Sei un esperto di essenze per profumi artigianali di Note del Chianti.
Il tuo compito è trovare le essenze più pertinenti per il profilo olfattivo dell'utente.

Hai accesso allo strumento di ricerca Qdrant. Usalo per cercare essenze semanticamente rilevanti.

Devi:
1. Analizzare il contesto (memoria, QnA) e formulare 1-3 query di ricerca pertinenti
2. Usare lo strumento search_qdrant per ogni query
3. Filtrare i risultati escludendo le essenze in blacklist: {{ $json.blacklistEssences }}
4. Selezionare le {{ $json.essences_per_carousel }} essenze più pertinenti e diverse tra loro
5. Restituire SOLO un JSON array con i campi: nome, categoria, contenuto_it, contenuto_en, descrizione, tipo, immagini

Lingua di risposta: {{ $json.default_language }}

Contesto conversazione:
Memoria: {{ $json.perfume_memory }}
QnA: {{ $json.qna_list }}
```
- Tools: Qdrant vector store (collection: `essenze`, credential: `Qdrant Local`)

**Node 3 — Parse Agent Output** (Code node)
```javascript
const raw = $input.first().json.output;
let chunks;
try {
  // Try to parse JSON from agent output
  const jsonMatch = raw.match(/\[[\s\S]*\]/);
  if (jsonMatch) {
    chunks = JSON.parse(jsonMatch[0]);
  } else {
    chunks = JSON.parse(raw);
  }
} catch (e) {
  chunks = [];
}
return [{ json: { chunks } }];
```

- [ ] **Step 2: Deploy**

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/9zoEkNJIukspijC1" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/kb-search.json | python3 -m json.tool
```

- [ ] **Step 3: Test — memory-based search**

Run with:
```json
{
  "qna_list": "Utente: Ricordo la pioggia sul bosco in autunno, foglie bagnate e terra",
  "perfume_memory": "mattina autunnale nel bosco toscano, umido, muschio, legno",
  "blacklistEssences": [],
  "essences_per_carousel": 4,
  "default_language": "it"
}
```

Expected: `chunks` array with 4 essenze, tutte con `nome` e `categoria` popolati, nessuna in blacklist.

- [ ] **Step 4: Test — blacklist filtering**

Take the `nome` of the first result from Step 3. Run again with that nome in `blacklistEssences`:
```json
{
  "blacklistEssences": ["<nome-from-step-3>"],
  ...
}
```

Expected: the blacklisted essence does NOT appear in results.

---

## Task 4: json-to-carousel sub-workflow

**Contract:**
- Input: `{ "chunks": [...], "default_language": "it" }`
- Output: `{ "carousel": { "layout": "Carousel", "cards": [...] } }`

- [ ] **Step 1: Build the workflow**

Nodes:

**Node 1 — Execute Workflow Trigger**

**Node 2 — Build Carousel** (Code node — adapted from original `Create Carousel` function)
```javascript
const { chunks, default_language } = $input.first().json;
const lang = default_language === "it" ? "it" : "en";

const cards = chunks.map(chunk => {
  const title = chunk.nome || "Essenza";
  const content = lang === "it" ? (chunk.contenuto_it || "") : (chunk.contenuto_en || "");
  const images = Array.isArray(chunk.immagini) ? chunk.immagini : [];
  const imageUrl = images.length > 0
    ? images[Math.floor(Math.random() * images.length)]
    : null;

  return {
    title,
    imageUrl,
    description: content,
    categoria: chunk.categoria,
    tipo: chunk.tipo,
    button: {
      label: title,
      value: JSON.stringify({
        nome: chunk.nome,
        categoria: chunk.categoria,
        contenuto_it: chunk.contenuto_it,
        contenuto_en: chunk.contenuto_en,
        descrizione: chunk.descrizione,
        tipo: chunk.tipo
      })
    }
  };
});

return [{ json: { carousel: { layout: "Carousel", cards } } }];
```

- [ ] **Step 2: Deploy**

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/<json-to-carousel-id>" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/json-to-carousel.json | python3 -m json.tool
```

- [ ] **Step 3: Test**

Run with:
```json
{
  "chunks": [
    {
      "nome": "Accord Macchia Mediterranea",
      "categoria": "Marina",
      "contenuto_it": "Aromatico, Balsamico",
      "contenuto_en": "Aromatic, Balsamic",
      "descrizione": "Accordo aromatico...",
      "tipo": "Testa",
      "immagini": ["https://example.com/img1.jpg", "https://example.com/img2.jpg"]
    }
  ],
  "default_language": "it"
}
```

Expected: `carousel.cards` array with 1 card, `imageUrl` is one of the two image URLs, `title` is "Accord Macchia Mediterranea".

---

## Task 5: show-language-buttons sub-workflow

**Contract:**
- Input: `{ "italian_labels": ["Per Lui", "Per Lei", "Per Entrambi"], "english_labels": ["For Him", "For Her", "For Both"], "default_language": "it" }`
- Output: `{ "buttons": [{"label": "Per Lui", "value": "For Him"}, ...] }`

> **Note:** This sub-workflow does NOT wait for user input — that happens in ROOT (ROOT sends the buttons in the response, the next user message is processed by ROOT). This sub-workflow only builds the buttons array.

- [ ] **Step 1: Build the workflow**

Nodes:

**Node 1 — Execute Workflow Trigger**

**Node 2 — Build Buttons** (Code node)
```javascript
const { italian_labels, english_labels, default_language } = $input.first().json;
const labels = default_language === "it" ? italian_labels : english_labels;

const buttons = labels.map((label, i) => ({
  label,
  value: english_labels[i] || label
}));

return [{ json: { buttons } }];
```

- [ ] **Step 2: Deploy**

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/qpLAp1waBP07k9JI" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/show-language-buttons.json | python3 -m json.tool
```

- [ ] **Step 3: Test — Italian**

Run with:
```json
{
  "italian_labels": ["Per Lui", "Per Lei", "Per Entrambi"],
  "english_labels": ["Uomo", "Donna", "Unisex"],
  "default_language": "it"
}
```

Expected:
```json
{ "buttons": [{"label": "Per Lui", "value": "Uomo"}, {"label": "Per Lei", "value": "Donna"}, {"label": "Per Entrambi", "value": "Unisex"}] }
```

- [ ] **Step 4: Test — English**

Run with same input but `"default_language": "en"`.

Expected:
```json
{ "buttons": [{"label": "Uomo", "value": "Uomo"}, {"label": "Donna", "value": "Donna"}, {"label": "Unisex", "value": "Unisex"}] }
```

---

## Task 6: Session cleanup cron workflow

**Contract:** Scheduled daily — deletes sessions older than 24 hours.

- [ ] **Step 1: Create the workflow**

Nodes:

**Node 1 — Schedule Trigger**
- Rule: Every day at 03:00

**Node 2 — Delete Old Sessions** (Postgres node)
- Query:
```sql
DELETE FROM sessions WHERE updated_at < now() - INTERVAL '24 hours';
```

**Node 3 — Log** (Set node)
- Field: `deleted_at` = `{{ $now }}`

- [ ] **Step 2: Deploy and activate**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/session-cleanup.json

# Then activate it
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows/<cleanup-id>/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

- [ ] **Step 3: Test manually**

Insert an old session:
```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "INSERT INTO sessions (id, state, updated_at) VALUES ('old-test', '{}', now() - INTERVAL '25 hours');"
```

Run the cleanup workflow manually in n8n test mode. Verify:
```bash
docker exec -it <postgres-container> psql -U <user> -d <db> -c \
  "SELECT id FROM sessions WHERE id = 'old-test';"
```

Expected: 0 rows.

---

## Phase 2 Complete — Verification Checklist

- [ ] `session-read`: returns merged defaults for new sessions, loaded state for existing
- [ ] `session-write`: upserts partial updates, merges with existing state
- [ ] `kb-search`: returns 4 relevant chunks, respects blacklist
- [ ] `json-to-carousel`: builds cards array with random image selection
- [ ] `show-language-buttons`: returns labels in correct language
- [ ] `session-cleanup`: deletes sessions older than 24h (cron active)
