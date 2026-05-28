# Phase 5: Evaluations Workflow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an automatic evaluation workflow that triggers at conversation completion, assesses quality using an AI judge, and stores results for review.

**Architecture:** ROOT calls `evaluation` sub-workflow when `current_step = "completed"`. The evaluation workflow receives `generalInfo` + full session state, runs an AI judge, and stores results in a Postgres table.

**Tech Stack:** n8n, AI Agent (OpenRouter), PostgreSQL

**Depends on:** Phase 3 (ROOT must reach `completed` state and call this workflow)

---

## Task 1: Create evaluations table in Postgres

- [ ] **Step 1: Connect to Postgres and run migration**

```bash
docker exec -it <postgres-container> psql -U <user> -d <db>
```

```sql
CREATE TABLE IF NOT EXISTS evaluations (
  id            SERIAL PRIMARY KEY,
  session_id    TEXT NOT NULL,
  evaluated_at  TIMESTAMPTZ DEFAULT now(),
  chosen_path   TEXT,
  essences_count INTEGER,
  has_name      BOOLEAN,
  scores        JSONB,
  summary       TEXT,
  general_info  JSONB
);

CREATE INDEX IF NOT EXISTS idx_evaluations_session ON evaluations (session_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_evaluated_at ON evaluations (evaluated_at);
```

- [ ] **Step 2: Verify**

```sql
\d evaluations
```

Expected: table with all columns.

---

## Task 2: Build the evaluation workflow

- [ ] **Step 1: Create the workflow via n8n API**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "evaluation", "nodes": [{"name": "Execute Workflow Trigger", "type": "n8n-nodes-base.executeWorkflowTrigger", "position": [250, 300], "parameters": {}}], "connections": {}}' | python3 -m json.tool
```

Note the returned `id` — `EVAL_WORKFLOW_ID`.

- [ ] **Step 2: Add the evaluation nodes**

**Node 1 — Execute Workflow Trigger** (already created)

**Node 2 — AI Judge** (AI Agent node)
- Model: `anthropic/claude-3.5-sonnet` via OpenRouter (use a smarter model for evaluation)
- System prompt:
```
Sei un valutatore esperto di conversazioni per la creazione di profumi artigianali.
Analizza la conversazione completata e fornisci una valutazione strutturata.

Criteri di valutazione (punteggio 1-5 per ciascuno):
1. completezza_essenze: L'utente ha selezionato almeno 3 essenze significative?
2. coerenza_percorso: Il percorso scelto (Memory/Inspiration/Renaissance) è stato completato correttamente?
3. qualita_memoria: Le informazioni raccolte sulla memoria/ispirazione sono ricche e specifiche?
4. nome_creativo: Il nome scelto per il profumo è evocativo e pertinente?
5. soddisfazione_stimata: Stima della soddisfazione dell'utente basata sul tono e completamento del journey.

Dati della conversazione:
- Percorso: {{ $json.chosenPath }}
- Genere target: {{ $json.target_gender }}
- Memoria/Ispirazione: {{ $json.perfume_memory }}
- QnA raccolta: {{ $json.qna_list }}
- Essenze selezionate: {{ JSON.stringify($json.selectedChunks) }}
- Nome profumo: {{ $json.perfumeName }}
- Note aggiuntive: {{ $json.additionalInfo }}

Rispondi SOLO in JSON:
{
  "scores": {
    "completezza_essenze": 1-5,
    "coerenza_percorso": 1-5,
    "qualita_memoria": 1-5,
    "nome_creativo": 1-5,
    "soddisfazione_stimata": 1-5
  },
  "score_medio": 1.0-5.0,
  "punti_di_forza": "...",
  "aree_di_miglioramento": "...",
  "summary": "breve riassunto della conversazione in 2-3 frasi"
}
```

**Node 3 — Parse Judge Output** (Code node)
```javascript
const raw = $input.first().json.output;
const session = $('Execute Workflow Trigger').first().json;
let evaluation;
try {
  evaluation = JSON.parse(raw.match(/\{[\s\S]*\}/)[0]);
} catch(e) {
  evaluation = { scores: {}, summary: "Parsing error", score_medio: 0 };
}

return [{
  json: {
    session_id: session.session_id,
    chosen_path: session.chosenPath,
    essences_count: (session.selectedChunks || []).length,
    has_name: !!session.perfumeName,
    scores: evaluation.scores,
    score_medio: evaluation.score_medio,
    summary: evaluation.summary,
    punti_di_forza: evaluation.punti_di_forza,
    aree_di_miglioramento: evaluation.aree_di_miglioramento,
    general_info: session.generalInfo || {}
  }
}];
```

**Node 4 — Save to Postgres** (Postgres node)
- Credential: `Sessions DB`
- Operation: Execute Query
```sql
INSERT INTO evaluations (session_id, chosen_path, essences_count, has_name, scores, summary, general_info)
VALUES (
  '{{ $json.session_id }}',
  '{{ $json.chosen_path }}',
  {{ $json.essences_count }},
  {{ $json.has_name }},
  '{{ JSON.stringify($json.scores) }}'::jsonb,
  '{{ $json.summary }}',
  '{{ JSON.stringify($json.general_info) }}'::jsonb
);
```

- [ ] **Step 3: Deploy the full workflow**

```bash
curl -s -X PATCH "$N8N_BASE_URL/api/v1/workflows/$EVAL_WORKFLOW_ID" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/evaluation.json | python3 -m json.tool
```

- [ ] **Step 4: Activate**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows/$EVAL_WORKFLOW_ID/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

---

## Task 3: Call evaluation from ROOT at completion

- [ ] **Step 1: Add Execute Workflow call in ROOT's `completed` branch**

In the ROOT workflow, after the finale message is prepared but before `session-write`, add:

**Node: Trigger Evaluation** (Execute Workflow node)
- Workflow: `evaluation`
- Run mode: "Run once for each item"
- Wait for sub-workflow: **No** (fire-and-forget — don't block the user response)
- Input: full session state `{{ $('Load Session').first().json }}`

> **Important:** Set "Wait for sub-workflow to finish" = OFF. The evaluation runs in the background — the user gets their finale message immediately without waiting for the evaluation to complete.

- [ ] **Step 2: Test evaluation trigger**

Complete a full test conversation through to `completed`. Then check:

```bash
docker exec -it <postgres-container> psql -U <user> -d <db> \
  -c "SELECT session_id, chosen_path, essences_count, score_medio, summary FROM evaluations ORDER BY evaluated_at DESC LIMIT 5;"
```

Expected: 1 row for the test conversation with scores populated.

---

## Task 4: (Optional) Evaluation dashboard view

- [ ] **Step 1: Create a Postgres view for easy reporting**

```sql
CREATE OR REPLACE VIEW evaluation_summary AS
SELECT
  session_id,
  evaluated_at,
  chosen_path,
  essences_count,
  has_name,
  (scores->>'completezza_essenze')::numeric AS score_essenze,
  (scores->>'coerenza_percorso')::numeric AS score_percorso,
  (scores->>'qualita_memoria')::numeric AS score_memoria,
  (scores->>'nome_creativo')::numeric AS score_nome,
  (scores->>'soddisfazione_stimata')::numeric AS score_soddisfazione,
  score_medio,
  summary
FROM evaluations
ORDER BY evaluated_at DESC;
```

- [ ] **Step 2: Verify the view**

```sql
SELECT * FROM evaluation_summary LIMIT 10;
```

---

## Phase 5 Complete — Verification Checklist

- [ ] `evaluations` table created with all columns
- [ ] Evaluation workflow deployed and activated
- [ ] ROOT triggers evaluation fire-and-forget at `completed` step
- [ ] After completing a test conversation, an evaluation row appears in Postgres within ~30s
- [ ] Scores (1-5) and summary populated correctly
- [ ] Evaluation does NOT block the user from receiving their finale message
