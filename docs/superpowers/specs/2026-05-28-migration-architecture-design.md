# Alchimista NdC — Architettura di Migrazione Voiceflow → n8n

**Data:** 2026-05-28  
**Stato:** Approvato

---

## Decisioni architetturali

| Componente | Decisione |
|---|---|
| Frontend | Custom (React/Vue), chiama n8n direttamente via webhook |
| Voiceflow | Eliminato completamente — nessun riferimento residuo |
| Knowledge Base | Directus (CMS catalogo essenze) → Qdrant (vector search), hook automatico re-index |
| Session state | PostgreSQL — tabella `sessions` nello stesso DB di n8n |
| AI | AI Agent node (n8n), provider OpenRouter, uniformemente per tutti gli agenti |
| Comunicazione frontend ↔ n8n | Webhook sincrono — risposta completa JSON, nessuno streaming |
| Struttura workflow | Un ROOT workflow con state machine `current_step`; sub-workflow solo per procedure riutilizzate |

---

## Architettura generale

```
Frontend (custom)
    │
    ├─ POST /webhook/root  {"session_id": "...", "message": "..."}
    │
    └─ riceve {"message": "...", "buttons": [...], "carousel": {...}}

ROOT workflow (n8n)
    ├─ session-read       →  carica stato da Postgres
    ├─ Switch (current_step)  →  instrada al blocco corretto
    ├─ [blocco: elabora, chiama AI, aggiorna stato]
    ├─ session-write      →  persiste stato aggiornato
    └─ Respond to Webhook →  risposta JSON completa al frontend

Sub-workflow (richiamati da ROOT)
    ├─ session-read        (utility, caricamento sessione)
    ├─ session-write       (utility, salvataggio sessione)
    ├─ kb-search           (AI Agent + Qdrant tool)
    ├─ json-to-carousel    (costruisce struttura carousel per frontend)
    └─ show-language-buttons  (mostra bottoni localizzati, cattura selezione)

Infrastruttura
    ├─ Postgres (stesso DB n8n)   →  tabella sessions
    ├─ Directus                   →  CMS catalogo essenze NdC
    ├─ Qdrant                     →  vector search essenze
    └─ OpenRouter                 →  tutti gli AI Agent node
```

---

## Macchina a stati — pattern per-turn

Ogni messaggio utente è una nuova esecuzione n8n. La posizione nella conversazione è tracciata dal campo `current_step` nel session state.

**Flusso di ogni turno:**
```
1. Frontend  →  POST { session_id, message }
2. ROOT      →  session-read (carica stato da Postgres)
3. ROOT      →  Switch su current_step → instrada al blocco giusto
4. Blocco    →  elabora messaggio, chiama AI/KB se necessario
5. Blocco    →  aggiorna current_step al valore successivo
6. ROOT      →  session-write (persiste stato aggiornato)
7. ROOT      →  Respond to Webhook → { message, buttons?, carousel? }
8. Frontend  →  renderizza risposta, attende prossimo input utente
```

**Valori di `current_step` (ROOT):**

| Valore | Corrisponde a |
|---|---|
| `init` | Inizio conversazione — Intro + Language Select |
| `waiting_target_gender` | Dopo Target Agent, attende selezione genere |
| `waiting_sorting_path` | Dopo Sorting Agent, attende scelta percorso |
| `waiting_memory_description` | Loop Memory Extraction — attende racconto memoria |
| `waiting_essence_selection` | Carousel essenze mostrato, attende selezione |
| `waiting_more_essences` | Chiede se aggiungere altre essenze |
| `waiting_5th_essence` | Prompt 5th Essence / Enhance Essence |
| `waiting_perfume_intensity` | Finish Perfume Creation — intensità |
| `waiting_additional_notes` | Note aggiuntive |
| `waiting_perfume_name` | Naming Ritual — attende nome profumo |
| `waiting_name_confirmation` | Conferma nome scelto |
| `completed` | Journey completato |

---

## Mapping nodi Voiceflow → n8n

| Voiceflow | n8n | Note |
|---|---|---|
| `response-prompt` | AI Agent node (OpenRouter) | Sempre, uniformemente per tutti gli agenti |
| `capture-v3` | Fine turno — `current_step` aggiornato, Respond to Webhook | Il messaggio successivo riprende da questo step |
| `function` | Code node (JS) | Codice originale adattato da `args.inputVars` a `$json` |
| `kb-search` | Sub-workflow `kb-search` (AI Agent + Qdrant tool) | L'agente gestisce query, valutazione, re-search autonomamente |
| `set-v3` | Set node | 1:1 |
| `condition-v3` | If / Switch node | 1:1 |
| `component` (riusabile) | Execute Workflow | Solo se chiamato più volte |
| `component` (singolo) | Inlineato in ROOT | Evita overhead di sub-workflow inutili |
| `goToNode` intra-workflow | Wire diretto tra nodi | |
| `goToNode` cross-workflow | Execute Workflow | |
| `message` | Set node → payload finale | Testo statico incluso nel JSON di risposta |
| `choice-v2` | Response JSON con campo `buttons[]` | Frontend renderizza i bottoni |
| `block` | Sticky Note (organizzazione visuale) | Nessun nodo eseguibile |
| `exit` | Fine branch senza Respond to Webhook | Sessione terminata |
| `api-v2` | HTTP Request node | Exa.ai search (inspiration path) |
| `markup_text` | Sticky Note | Solo annotazione visuale |

---

## Sub-workflow — interfacce

### `session-read`
- **Input:** `{ session_id: string }`
- **Output:** intero session state (JSONB con defaults merged)
- **Note:** se la sessione non esiste, crea riga con valori di default

### `session-write`
- **Input:** `{ session_id: string, updates: object }`
- **Output:** —
- **Note:** upsert parziale — merge di `updates` sullo stato esistente

### `kb-search`
- **Input:** `{ qna_list, perfume_memory, blacklistEssences, essences_per_carousel, default_language }`
- **Output:** `{ chunks: array }` — lista essenze filtrate e rilevanti
- **Implementazione:** AI Agent (OpenRouter) con Qdrant come tool. L'agente formula la query, valuta i risultati, può ri-cercare se i risultati sono insufficienti o tutti in blacklist.

### `json-to-carousel`
- **Input:** `{ chunks: array, default_language: string }`
- **Output:** `{ carousel: object }` — struttura renderizzabile dal frontend
- **Note:** sostituisce le funzioni `Create Carousel` / `Create Essence Carousel`

### `show-language-buttons`
- **Input:** `{ italian_labels: string[], english_labels: string[], default_language: string }`
- **Output:** `{ final_label: string }` — label EN corrispondente alla selezione
- **Note:** chiamato 17 volte in ROOT — sub-workflow giustificato

---

## Schema sessione (Postgres)

```sql
CREATE TABLE sessions (
  id          TEXT PRIMARY KEY,
  state       JSONB NOT NULL DEFAULT '{}',
  updated_at  TIMESTAMPTZ DEFAULT now()
);
```

**Campi chiave nel JSONB `state`:**

```json
{
  "current_step": "waiting_memory_description",
  "default_language": "it",
  "target_gender": "Donna",
  "perfume_type": null,
  "chosenPath": null,
  "perfume_memory": null,
  "selectedChunks": [],
  "blacklistEssences": [],
  "essences_per_carousel": 4,
  "currentEssenceIndex": 0,
  "final_essences": null,
  "qna_list": "",
  "generalInfo": null,
  "perfumeName": null,
  "tone_of_voice": "...",
  "enough_info": false
}
```

---

## Payload API — formato risposta

Ogni risposta di ROOT al frontend ha questa struttura:

```json
{
  "message": "Testo della risposta AI o messaggio statico",
  "buttons": [
    { "label": "Per Lui", "value": "Uomo" },
    { "label": "Per Lei", "value": "Donna" }
  ],
  "carousel": {
    "layout": "Carousel",
    "cards": [ ... ]
  },
  "session_id": "abc-123",
  "current_step": "waiting_target_gender"
}
```

I campi `buttons` e `carousel` sono presenti solo quando necessario (null altrimenti). Il frontend decide il rendering in base a quali campi sono popolati.
