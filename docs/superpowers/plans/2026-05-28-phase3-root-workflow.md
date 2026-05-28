# Phase 3: ROOT Workflow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the main conversation workflow — a state machine that routes each user message to the correct conversation block based on `current_step`.

**Architecture:** Single n8n workflow. Every execution: session-read → Switch(current_step) → process block → session-write → Respond to Webhook. Each `capture-v3` Voiceflow node becomes a "turn end" — ROOT sets `current_step` and responds; the next user message resumes at that step.

**Tech Stack:** n8n, AI Agent (OpenRouter), Execute Workflow (sub-workflows from Phase 2), Postgres, HTTP Request (Exa.ai for Inspiration path)

**Depends on:** Phase 0 (credentials), Phase 1 (Qdrant data), Phase 2 (all sub-workflows deployed and tested)  
**Required by:** Phase 4 (frontend calls ROOT), Phase 5 (evaluations triggered from ROOT)

---

## Reference: current_step values

| `current_step` | Description |
|---|---|
| `init` | First message — show language buttons |
| `waiting_target_gender` | Language set — waiting for gender selection |
| `waiting_sorting_path` | Target gender set — Sorting Agent deciding path |
| `waiting_memory_input` | Memory path: waiting for memory description |
| `memory_loop` | Memory Extraction Agent still gathering info |
| `waiting_essence_selection` | Carousel shown — waiting for essence click |
| `waiting_more_essences` | After selection — ask if more essences needed |
| `waiting_5th_essence` | Prompt for 5th/enhanced essence |
| `waiting_perfume_intensity` | Finish Perfume Creation — waiting for intensity |
| `waiting_additional_notes` | Waiting for additional notes |
| `waiting_perfume_name` | Naming Ritual — waiting for name |
| `waiting_name_confirmation` | Confirm name — yes/no |
| `completed` | Journey complete — triggers evaluation |

---

## Reference: ROOT webhook URL

After the ROOT workflow is created and activated, the webhook URL is:
`https://n8n.mattiagirellini.com/webhook/alchimista`

Every request: `POST { "session_id": "...", "message": "..." }`  
Every response: `{ "message": "...", "buttons": null|[...], "carousel": null|{...}, "current_step": "..." }`

---

## Task 1: Create ROOT workflow skeleton

- [ ] **Step 1: Create the ROOT workflow with Webhook trigger**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ROOT",
    "nodes": [
      {
        "name": "Webhook",
        "type": "n8n-nodes-base.webhook",
        "position": [250, 300],
        "parameters": {
          "path": "alchimista",
          "responseMode": "responseNode",
          "httpMethod": "POST"
        }
      }
    ],
    "connections": {}
  }' | python3 -m json.tool
```

Note the returned `id` — this is `ROOT_WORKFLOW_ID`.

- [ ] **Step 2: Verify webhook URL is available**

```bash
curl -s -X POST "https://n8n.mattiagirellini.com/webhook-test/alchimista" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test", "message": "hello"}'
```

Expected: some response (even an error) confirms the webhook path is registered.

---

## Task 2: Add session-read and main Switch node

- [ ] **Step 1: Add the session-read call and Switch**

Update the ROOT workflow to add after the Webhook node:

**Node: Load Session** (Execute Workflow node)
- Workflow: `session-read`
- Input: `{ "session_id": "{{ $json.body.session_id }}" }`

**Node: Route by Step** (Switch node)
- Input value: `{{ $json.current_step }}`
- Cases (add one for each `current_step` value in the reference table above)

**Node: Prepare Response** (Set node — shared final node)
- Fields:
  - `message`: `{{ $json.message }}`
  - `buttons`: `{{ $json.buttons ?? null }}`
  - `carousel`: `{{ $json.carousel ?? null }}`
  - `current_step`: `{{ $json.current_step }}`

**Node: Respond to Webhook** (Respond to Webhook node)
- Response code: 200
- Response body: `{{ $json }}`

- [ ] **Step 2: Add session-write before Prepare Response**

**Node: Save Session** (Execute Workflow node)
- Workflow: `session-write`
- Input: `{ "session_id": "{{ $('Load Session').first().json.session_id }}", "updates": "{{ $json }}" }`

> Connect every block's output → Save Session → Prepare Response → Respond to Webhook.

- [ ] **Step 3: Test skeleton — unknown step**

Run a test POST to the webhook with `{"session_id": "test-root-001", "message": "hello"}`.

Expected: workflow runs, session-read creates a new session with `current_step: "init"`, Switch routes to `init` branch (not yet implemented — will return empty response or error). Verify the session was created in Postgres.

---

## Task 3: Block — init (Language Select)

**Triggered by:** `current_step = "init"`  
**What it does:** Greet the user and show language selection buttons.  
**Sets:** `current_step → "waiting_target_gender"` (language is set by button click, handled in waiting_target_gender)

- [ ] **Step 1: Add the init block nodes**

After the `init` Switch branch:

**Node: Build Language Buttons** (Execute Workflow node)
- Workflow: `show-language-buttons`
- Input:
```json
{
  "italian_labels": ["🇮🇹 Italiano", "🇬🇧 English"],
  "english_labels": ["it", "en"],
  "default_language": "it"
}
```

**Node: Set Init Response** (Set node)
```javascript
{
  "message": "Benvenuto, anima errante... Sono L'Alchimista del Chianti, custode di segreti olfattivi tra le colline di Siena. In quale lingua desideri intraprendere questo viaggio?\n\nWelcome, wandering soul... I am L'Alchimista del Chianti. In which language shall we begin?",
  "buttons": "{{ $json.buttons }}",
  "current_step": "waiting_target_gender"
}
```

- [ ] **Step 2: Test**

POST `{"session_id": "test-init-001", "message": "start"}`.

Expected response:
```json
{
  "message": "Benvenuto...",
  "buttons": [{"label": "🇮🇹 Italiano", "value": "it"}, {"label": "🇬🇧 English", "value": "en"}],
  "current_step": "waiting_target_gender"
}
```

---

## Task 4: Block — waiting_target_gender

**Triggered by:** `current_step = "waiting_target_gender"`  
**User message:** button value `"it"` or `"en"` (language selection), then gender buttons  
**What it does:** Set `default_language`, call Target Agent, show gender buttons  
**Sets:** `current_step → "waiting_sorting_path"`

- [ ] **Step 1: Add the block nodes**

**Node: Set Language** (Set node)
```javascript
// $json.message is the button value from language selection: "it" or "en"
// But on first call, the language hasn't been set yet.
// Check if message is "it" or "en" — if so, set language; otherwise use session language.
{
  "default_language": "{{ ['it','en'].includes($('Webhook').first().json.body.message) ? $('Webhook').first().json.body.message : $('Load Session').first().json.default_language }}"
}
```

**Node: Target Agent** (AI Agent node)
- Model: `anthropic/claude-3.5-haiku` via OpenRouter
- System prompt:
```
{{ $('Load Session').first().json.tone_of_voice }}

Sei il Target Agent. Il tuo compito è chiedere per chi viene creato il profumo.
Lingua: {{ $json.default_language }}

Fai UNA sola domanda poetica per scoprire il target (Maschile/Femminile/Universale).
Poi mostra i bottoni — non decidere tu, lascia scegliere all'utente.

Rispondi in JSON:
{"message": "testo poetico della domanda"}
```
- Input: conversation context from session

**Node: Parse Target Agent Output** (Code node)
```javascript
const raw = $input.first().json.output;
const parsed = JSON.parse(raw.match(/\{[\s\S]*\}/)[0]);
return [{ json: { message: parsed.message } }];
```

**Node: Build Gender Buttons** (Execute Workflow node)
- Workflow: `show-language-buttons`
- Input:
```json
{
  "italian_labels": ["Per Lui", "Per Lei", "Per Entrambi"],
  "english_labels": ["Uomo", "Donna", "Unisex"],
  "default_language": "{{ $('Load Session').first().json.default_language }}"
}
```

**Node: Set Target Response** (Set node)
```json
{
  "message": "{{ $('Parse Target Agent Output').first().json.message }}",
  "buttons": "{{ $('Build Gender Buttons').first().json.buttons }}",
  "current_step": "waiting_sorting_path"
}
```

- [ ] **Step 2: Test**

POST `{"session_id": "test-target-001", "message": "it"}` (simulating language button click).

Expected: AI-generated question about gender, 3 gender buttons, `current_step: "waiting_sorting_path"`.

---

## Task 5: Block — waiting_sorting_path

**Triggered by:** `current_step = "waiting_sorting_path"`  
**User message:** button value `"Uomo"` | `"Donna"` | `"Unisex"`  
**What it does:** Save `target_gender`, run Sorting Agent, show 3 path buttons  
**Sets:** `current_step → "waiting_memory_input"` | `"waiting_essence_selection"` (inspiration) | sets `chosen_fragrance` (renaissance)

- [ ] **Step 1: Add the block nodes**

**Node: Save Target Gender** (Set node)
```json
{ "target_gender": "{{ $('Webhook').first().json.body.message }}" }
```

**Node: Sorting Agent** (AI Agent node)
- Model: `anthropic/claude-3.5-haiku` via OpenRouter
- System prompt:
```
{{ $('Load Session').first().json.tone_of_voice }}

Sei il Sorting Agent. Rivela i tre Percorsi di Creazione all'utente.
Target scelto: {{ $json.target_gender }}
Lingua: {{ $('Load Session').first().json.default_language }}

Presenta i 3 percorsi con poesia e lascia scegliere tramite bottoni.
Non decidere tu il percorso — mostra i bottoni e aspetta.

Rispondi in JSON:
{"message": "testo poetico che illustra i 3 percorsi"}
```

**Node: Parse Sorting Output** (Code node — same pattern as Task 4)

**Node: Build Path Buttons** (Execute Workflow node)
- Input:
```json
{
  "italian_labels": ["Percorso della Memoria", "Percorso dell'Ispirazione", "Percorso del Rinascimento"],
  "english_labels": ["memory", "inspiration", "renaissance"],
  "default_language": "{{ $('Load Session').first().json.default_language }}"
}
```

**Node: Set Sorting Response** (Set node)
```json
{
  "message": "{{ $('Parse Sorting Output').first().json.message }}",
  "buttons": "{{ $('Build Path Buttons').first().json.buttons }}",
  "target_gender": "{{ $json.target_gender }}",
  "current_step": "waiting_memory_input"
}
```

> **Note:** `current_step` is set to `waiting_memory_input` as default. The actual routing to memory/inspiration/renaissance happens in the NEXT turn when the user clicks a path button. That is handled in Task 6.

- [ ] **Step 2: Test**

POST `{"session_id": "test-sorting-001", "message": "Donna"}` (session must be at `waiting_sorting_path`).

Expected: Sorting Agent poetic message, 3 path buttons, `target_gender: "Donna"` saved.

---

## Task 6: Block — waiting_memory_input (path routing + Memory start)

**Triggered by:** `current_step = "waiting_memory_input"`  
**User message:** `"memory"` | `"inspiration"` | `"renaissance"` (button value from path selection)  
**What it does:** Routes to the correct path. For Memory: starts Memory Extraction Agent loop.

- [ ] **Step 1: Add path routing Switch**

**Node: Route to Path** (Switch node)
- Value: `{{ $('Webhook').first().json.body.message }}`
- Cases: `"memory"` → Memory branch, `"inspiration"` → Inspiration branch, `"renaissance"` → Renaissance branch

**Memory branch:**

**Node: Memory Extraction Agent** (AI Agent node)
- Model: `anthropic/claude-3.5-haiku`
- System prompt:
```
{{ $('Load Session').first().json.tone_of_voice }}

Sei il Memory Extraction Agent. Il tuo compito è raccogliere dettagli sensoriali ed emotivi
del ricordo dell'utente che vuole trasformare in profumo. MAI nominare essenze specifiche.

Fai domande poetiche una alla volta per esplorare: luogo, stagione, emozione, sensazione,
colore, suono, temperatura associati al ricordo.

Dati raccolti finora: {{ $('Load Session').first().json.qna_list }}
Lingua: {{ $('Load Session').first().json.default_language }}

Quando hai raccolto abbastanza informazioni (almeno 3-4 scambi significativi), imposta enough_info: true.

Rispondi in JSON:
{"message": "prossima domanda poetica", "enough_info": false, "qna_update": "sintesi di questo scambio"}
```
- Input: `$('Webhook').first().json.body.message` + session context

**Node: Parse Memory Agent Output** (Code node)
```javascript
const raw = $input.first().json.output;
const parsed = JSON.parse(raw.match(/\{[\s\S]*\}/)[0]);
const session = $('Load Session').first().json;
const newQna = session.qna_list + (parsed.qna_update ? `\n${parsed.qna_update}` : "");
return [{
  json: {
    message: parsed.message,
    enough_info: parsed.enough_info || false,
    qna_list: newQna,
    chosenPath: "memory",
    current_step: parsed.enough_info ? "waiting_essence_selection" : "memory_loop"
  }
}];
```

- [ ] **Step 2: Add Inspiration branch**

**Node: Inspiration Intro** (Set node)
- Message: AI-generated intro for Inspiration path (or use a Set node with static poetic text asking for the reference perfume name)
- `current_step`: `"waiting_inspiration_fragrance"` (add this step to the Switch in Task 2)
- `chosenPath`: `"inspiration"`

- [ ] **Step 3: Add Renaissance branch**

**Node: Renaissance Intro** (Set node)
- Build buttons showing the 16 NdC perfumes from `perfumes_available`
- `current_step`: `"waiting_renaissance_choice"`
- `chosenPath`: `"renaissance"`

- [ ] **Step 4: Test Memory path**

POST with session at `waiting_memory_input`, message `"memory"`.

Expected: poetic question, `current_step: "memory_loop"`, `qna_list` updated.

---

## Task 7: Block — memory_loop

**Triggered by:** `current_step = "memory_loop"`  
**User message:** user's memory description  
**What it does:** Continue Memory Extraction until `enough_info = true`, then trigger KB search

- [ ] **Step 1: Reuse Memory Extraction Agent**

This block is identical to the Memory branch in Task 6 — same agent, same parse logic.

When `enough_info = true`, set `current_step = "waiting_essence_selection"` and trigger the KB search sub-workflow immediately (don't wait for another user message):

**Node: Check enough_info** (If node)
- Condition: `{{ $json.enough_info === true }}`
- True branch → KB search + build carousel → respond with carousel
- False branch → respond with next question

**True branch:**

**Node: KB Search** (Execute Workflow node)
- Workflow: `kb-search`
- Input: `{ "qna_list": "{{ $json.qna_list }}", "perfume_memory": "{{ $('Load Session').first().json.perfume_memory }}", "blacklistEssences": "{{ $('Load Session').first().json.blacklistEssences }}", "essences_per_carousel": "{{ $('Load Session').first().json.essences_per_carousel }}", "default_language": "{{ $('Load Session').first().json.default_language }}" }`

**Node: Build Carousel** (Execute Workflow node)
- Workflow: `json-to-carousel`
- Input: `{ "chunks": "{{ $json.chunks }}", "default_language": "{{ $('Load Session').first().json.default_language }}" }`

**Node: Set Essence Response** (Set node)
```json
{
  "message": "Ho sentito il profumo della tua memoria... ecco le essenze che la evocano:",
  "carousel": "{{ $json.carousel }}",
  "current_step": "waiting_essence_selection"
}
```

- [ ] **Step 2: Test memory loop continuation**

POST with session at `memory_loop`, a short memory description.

Expected: another question, `enough_info: false`, `memory_loop` continues.

- [ ] **Step 3: Test enough_info trigger**

Manually set `enough_info: true` in the session state, then POST a message.

Expected: carousel with 4 essences, `current_step: "waiting_essence_selection"`.

---

## Task 8: Block — waiting_essence_selection

**Triggered by:** `current_step = "waiting_essence_selection"`  
**User message:** JSON string of selected chunk (from carousel button `value` field)  
**What it does:** Parse selection, add to `selectedChunks`, check if max reached, ask for more or continue

- [ ] **Step 1: Add the block**

**Node: Parse Selection** (Code node)
```javascript
const message = $('Webhook').first().json.body.message;
const session = $('Load Session').first().json;
let selectedChunk;
try {
  selectedChunk = JSON.parse(message);
} catch(e) {
  return [{ json: { error: "invalid_selection", message: "Selezione non valida, riprova." } }];
}

const chunks = session.selectedChunks || [];
// Avoid duplicates
if (!chunks.find(c => c.nome === selectedChunk.nome)) {
  chunks.push(selectedChunk);
}

const maxReached = chunks.length >= 4;
return [{
  json: {
    selectedChunks: chunks,
    selectedChunksLength: chunks.length,
    maxReached,
    lastSelected: selectedChunk
  }
}];
```

**Node: Check Max Essences** (If node)
- Condition: `{{ $json.maxReached }}`
- True (4 essences): → ask about 5th essence
- False (< 4): → show more essences or ask if satisfied

**False branch — ask for more:**

**Node: Build More/Done Buttons** (Execute Workflow node)
- Input:
```json
{
  "italian_labels": ["Aggiungi altra essenza", "Vai avanti"],
  "english_labels": ["add_more", "continue"],
  "default_language": "{{ $('Load Session').first().json.default_language }}"
}
```

**Node: Set More Response** (Set node)
```json
{
  "message": "Essenza aggiunta. Vuoi esplorare altre essenze o procedere?",
  "buttons": "{{ $json.buttons }}",
  "selectedChunks": "{{ $('Parse Selection').first().json.selectedChunks }}",
  "current_step": "waiting_more_essences"
}
```

**True branch — 4 essences:**

→ Set `current_step: "waiting_5th_essence"` (Task 9)

- [ ] **Step 2: Test selection**

Set session at `waiting_essence_selection` with `selectedChunks: []`. POST with a chunk JSON.

Expected: `selectedChunks` has 1 item, buttons for more/continue.

---

## Task 9: Block — waiting_more_essences and waiting_5th_essence

**waiting_more_essences:** User chose "add_more" → trigger another KB search cycle; User chose "continue" → go to intensity

**waiting_5th_essence:** Ask about enhancing an existing essence or adding a 5th

- [ ] **Step 1: waiting_more_essences block**

**Node: Route More/Continue** (Switch node)
- Value: `{{ $('Webhook').first().json.body.message }}`
- `"add_more"`: → KB Search again (same as Task 7 true branch) → carousel → back to `waiting_essence_selection`
- `"continue"`: → Set `current_step: "waiting_perfume_intensity"`

- [ ] **Step 2: waiting_5th_essence block**

**Node: 5th Essence Agent** (AI Agent node)
- Asks poetically if the user wants to add a 5th essence or enhance an existing one
- Shows buttons: add 5th, enhance existing, skip

**Node: Build 5th Essence Buttons** (Execute Workflow node)
- Labels: "Aggiungi 5a essenza" / "Potenzia un'essenza" / "Vai avanti"

Set `current_step: "waiting_perfume_intensity"` when user skips.

---

## Task 10: Block — waiting_perfume_intensity and waiting_additional_notes

- [ ] **Step 1: waiting_perfume_intensity block**

**Node: Intensity Agent** (AI Agent node)
- Asks poetically about desired intensity (leggero/moderato/intenso)

**Node: Build Intensity Buttons** (Execute Workflow node)
- Labels: "Leggero" / "Moderato" / "Intenso"
- Values: `"light"` / `"moderate"` / `"intense"`

Set `current_step: "waiting_additional_notes"`.

- [ ] **Step 2: waiting_additional_notes block**

**Node: Additional Notes Agent** (AI Agent node)
- Asks for any additional notes (occasions, wishes, special requests)
- This is an open text input — no buttons

Set `current_step: "waiting_perfume_name"`.

---

## Task 11: Block — waiting_perfume_name and waiting_name_confirmation

- [ ] **Step 1: waiting_perfume_name block**

**Node: Naming Ritual Agent** (AI Agent node)
- Poetic prompt inviting the user to name their creation
- Shows name suggestions based on `generalInfo`

**Node: Perfect Prompt Generator** (Execute Workflow node — calls the inline Perfect Prompt Generator logic)
- Generates `perfume_description` from all collected data
- Stores in session state

Set `current_step: "waiting_name_confirmation"`.

- [ ] **Step 2: waiting_name_confirmation block**

**Node: Save Name** (Set node)
- `perfumeName`: `$('Webhook').first().json.body.message`

**Node: Build Confirm Buttons** (Execute Workflow node)
- Labels: "Sì, è perfetto" / "Scegli un altro nome"
- Values: `"confirm"` / `"rename"`

**If confirmed:**

**Node: Create generalInfo** (Code node — adapted from `create-general-info` Voiceflow function)
```javascript
const s = $('Load Session').first().json;
return [{
  json: {
    generalInfo: {
      perfumeName: $('Webhook').first().json.body.message,
      target_gender: s.target_gender,
      perfume_type: s.perfume_type,
      chosenPath: s.chosenPath,
      selectedChunks: s.selectedChunks,
      qna_list: s.qna_list,
      perfume_memory: s.perfume_memory,
      perfume_intensity: s.perfume_intensity,
      additionalInfo: s.additionalInfo,
      default_language: s.default_language
    },
    perfumeName: $('Webhook').first().json.body.message,
    current_step: "completed"
  }
}];
```

**Node: Finale Message** (Set node)
- A poetic closing message celebrating the creation
- `current_step: "completed"`

---

## Task 12: Inspiration and Renaissance paths

> These paths follow the same state machine pattern. Key differences:

**Inspiration path:** After path selection, use Exa.ai to search the reference perfume → extract notes → run KB search with those notes as context.

**Node: Exa Search** (HTTP Request node)
- URL: `https://api.exa.ai/search`
- Headers: `x-api-key: {{ $credentials.ExaAI }}`
- Body: `{ "query": "{{ $('Webhook').first().json.body.message }} perfume fragrance notes", "numResults": 3 }`

**Renaissance path:** User selects an NdC perfume from the catalog (buttons with the 16 perfume names) → runs KB search using that perfume's name as context.

Both paths merge into the `waiting_essence_selection` step once KB results are ready.

---

## Task 13: Activate ROOT and smoke test

- [ ] **Step 1: Activate ROOT**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows/$ROOT_WORKFLOW_ID/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

- [ ] **Step 2: Full conversation smoke test — Memory path**

```bash
SESSION="smoke-test-$(date +%s)"
BASE="https://n8n.mattiagirellini.com/webhook/alchimista"

# Turn 1: start
curl -s -X POST $BASE -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION\", \"message\": \"start\"}" | python3 -m json.tool

# Turn 2: select Italian
curl -s -X POST $BASE -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION\", \"message\": \"it\"}" | python3 -m json.tool

# Turn 3: select gender
curl -s -X POST $BASE -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION\", \"message\": \"Donna\"}" | python3 -m json.tool

# Turn 4: select Memory path
curl -s -X POST $BASE -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION\", \"message\": \"memory\"}" | python3 -m json.tool

# Turn 5: give a memory
curl -s -X POST $BASE -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION\", \"message\": \"Ricordo la mia nonna che cucinava con lavanda e rosmarino in Toscana\"}" | python3 -m json.tool
```

Each turn should return a valid JSON with `message` and `current_step` progressing correctly.

- [ ] **Step 3: Commit ROOT workflow JSON**

Export the workflow and save:
```bash
curl -s "$N8N_BASE_URL/api/v1/workflows/$ROOT_WORKFLOW_ID" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" > workflows/root.json
git add workflows/root.json
git commit -m "feat: add ROOT workflow"
```

---

## Phase 3 Complete — Verification Checklist

- [ ] All 12 `current_step` values handled in the Switch node
- [ ] Memory path: init → language → gender → sorting → memory loop → carousel → essence selection → intensity → notes → naming → complete
- [ ] Inspiration path: init → ... → Exa search → KB search → carousel → ...
- [ ] Renaissance path: init → ... → NdC catalog → KB search → carousel → ...
- [ ] `session-read` and `session-write` called at start/end of every turn
- [ ] `generalInfo` created at journey completion
- [ ] `current_step: "completed"` reached at end of all three paths
- [ ] Smoke test passes for Memory path (all turns return valid JSON)
