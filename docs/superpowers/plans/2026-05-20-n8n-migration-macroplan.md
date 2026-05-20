# Alchimista NdC → n8n Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reimplementare l'intero flusso conversazionale Alchimista NdC (attualmente su Voiceflow) in n8n, mantenendo tutta la logica di business, gli agenti AI, le funzioni JavaScript e il Knowledge Base.

**Architecture:** Ogni diagramma Voiceflow diventa un n8n workflow separato. Il ROOT workflow è il motore principale; i sotto-diagrammi diventano sub-workflow richiamati via "Execute Workflow". Lo stato della sessione (le variabili Voiceflow) è persistito esternamente (Supabase o Redis) e ricaricato ad ogni turno di conversazione.

**Tech Stack:** n8n (Hetzner), Claude AI models (API Anthropic), Voiceflow KB API (o vector store sostitutivo), Supabase per la session state, webhook per la comunicazione con il frontend.

---

## Riferimenti

- Documentazione source: `docs/` (tutti i file .md generati)
- Sorgente Voiceflow: `alchimista.json`
- Index task: `docs/00-index.md`
- Mapping node types: `docs/migration-mapping.md`
- Variabili: `docs/variables.md`

---

## Fase 0 — Setup Infrastruttura

**Obiettivo:** Predisporre tutto ciò che serve prima di costruire i workflow.

- [ ] **0.1 — Credenziali n8n**
  - Creare credential HTTP Header Auth per Voiceflow KB API (`api_key`)
  - Creare credential Anthropic API (Claude)
  - Creare credential Supabase (session store)

- [ ] **0.2 — Session state design**
  - Definire lo schema della tabella sessione su Supabase (una riga per sessione, colonne = le 101 variabili Voiceflow rilevanti)
  - Scrivere due helper workflow n8n: `Session Read` e `Session Write` (riutilizzati da tutti i workflow principali)

- [ ] **0.3 — Struttura workflow**
  - Creare in n8n le cartelle/tag per organizzare i workflow (ROOT, sub-workflows, utilities)
  - Creare workflow vuoti "placeholder" per ogni diagramma (così gli Execute Workflow node possono già referenziarli)

---

## Fase 1 — Funzioni JavaScript (18 funzioni → Code nodes)

**Obiettivo:** Avere snippet testati per ogni funzione Voiceflow prima di costruire i workflow che le usano.

Ogni funzione diventa un n8n Code node riutilizzabile (o copiabile). Non è necessario un workflow dedicato per ogni funzione — vengono incluse inline nei workflow che le usano — ma è utile testarle individualmente prima.

- [ ] **1.1** — `create-carousel` / `create-essence-carousel`
- [ ] **1.2** — `create-essence-buttons` / `show-buttons`
- [ ] **1.3** — `add-essence-to-selection` / `remove-essence`
- [ ] **1.4** — `process-selected-chunk` / `post-process-essences`
- [ ] **1.5** — `remove-chosen-essences` / `manage-blacklisted-essences`
- [ ] **1.6** — `update-chunk-to-fetch` / `add-fetched-chunk`
- [ ] **1.7** — `verify-id`
- [ ] **1.8** — `create-general-info`
- [ ] **1.9** — `show-languaged-buttons` / `find-italian-choice`

Documentazione: `docs/functions/*.md`

---

## Fase 2 — Agenti AI (14 agenti → AI Agent nodes)

**Obiettivo:** Avere ogni system prompt pronto e testato come n8n AI Agent node.

- [ ] **2.1** — Routing Agent
- [ ] **2.2** — Target Agent
- [ ] **2.3** — Sorting Agent
- [ ] **2.4** — Memory Extraction Agent v1 + v2
- [ ] **2.5** — Essence Selection Agent
- [ ] **2.6** — Choice Description Agent
- [ ] **2.7** — Carousel Pipeline Agents (Clarify / Select / Generate / Request / Handle) — 4 agenti

Per ogni agente: creare l'AI Agent node, incollare il system prompt, collegare le variabili di input (`qna_list`, `tone_of_voice`, `default_language`, ecc.).

Documentazione: `docs/agents/*.md`

---

## Fase 3 — Sub-workflow semplici (workflow autonomi, pochi nodi)

Ordine: dal più semplice al più complesso.

- [ ] **3.1** — `Perfume Type Selector` (7 nodi) — `docs/diagrams/Perfume-Type-Selector.md`
- [ ] **3.2** — `Show Language Buttons` (9 nodi) — `docs/diagrams/Show-Language-Buttons.md`
- [ ] **3.3** — `Target Selector` (12 nodi) — `docs/diagrams/Target-Selector.md`
- [ ] **3.4** — `Select Essence` (11 nodi) — `docs/diagrams/Select-Essence.md`
- [ ] **3.5** — `Perfect Prompt Generator` (10 nodi) — `docs/diagrams/Perfect-Prompt-Generator.md`

---

## Fase 4 — Sub-workflow complessi (loop KB + carousel)

- [ ] **4.1** — `KB Search 24` (24 nodi) — `docs/diagrams/KB-Search-24.md`
- [ ] **4.2** — `KB Search 48` (48 nodi, loop iterativo) — `docs/diagrams/KB-Search-48.md`
- [ ] **4.3** — `JSON list to carousel` (36 nodi, pipeline rendering) — `docs/diagrams/JSON-list-to-carousel.md`

---

## Fase 5 — ROOT workflow (per sezioni)

Il ROOT è il flusso principale (314 nodi). Va costruito sezione per sezione, nell'ordine logico del journey. Ogni sezione è un'unità testabile.

- [ ] **5.1** — Intro + Gender Select → Target Selector call
- [ ] **5.2** — Sorting Agent + Path Selection (3 path: Memory / Inspiration / Renaissance)
- [ ] **5.3** — Memory Path (Memory Extraction Agent loop)
- [ ] **5.4** — Essence Path Intro (Inspiration path)
- [ ] **5.5** — Fragrance Path Intro (Renaissance path)
- [ ] **5.6** — KB Search Loop (Get Essences → Show Carousel → Analyze)
- [ ] **5.7** — Essence Follow Up + 5th Essence Prompt
- [ ] **5.8** — Finish Perfume Creation (Intensity + Additional Notes)
- [ ] **5.9** — Naming Ritual + Save Name
- [ ] **5.10** — Finish Journey + generalInfo export
- [ ] **5.11** — Essence Select + Remove sub-blocks (button UI)

Documentazione: `docs/diagrams/ROOT.md` + `docs/00-index.md` per i file da caricare per ogni sezione.

---

## Fase 6 — Integrazione e test end-to-end

- [ ] **6.1** — Test del percorso Memory completo (dall'intro alla scelta del nome)
- [ ] **6.2** — Test del percorso Inspiration completo
- [ ] **6.3** — Test del percorso Renaissance completo
- [ ] **6.4** — Test lingue: italiano / inglese
- [ ] **6.5** — Test edge cases: utente cambia idea, essenze rimosse, sessione vuota
- [ ] **6.6** — Performance: verificare latenza KB search + carousel rendering

---

## Note sull'ordine di esecuzione

Le fasi sono dipendenti in questo modo:

```
Fase 0 (infrastruttura)
  └── Fase 1 (funzioni) + Fase 2 (agenti)  ← parallele
        └── Fase 3 (sub-workflow semplici)
              └── Fase 4 (sub-workflow complessi)
                    └── Fase 5 (ROOT, sezione per sezione)
                          └── Fase 6 (test e2e)
```

Le Fasi 1 e 2 possono procedere in parallelo. Ogni sotto-fase di Fase 5 può essere eseguita solo dopo che i sub-workflow che chiama (Fasi 3 e 4) sono pronti.

---

## Decisioni aperte (da risolvere in Fase 0)

1. **Session store**: Supabase (SQL, facile da ispezionare) vs Redis (più veloce, TTL nativo) — raccomandato Supabase per semplicità di debug.
2. **KB**: Mantenere la Voiceflow KB API via HTTP Request, oppure migrare i dati su un vector store n8n-nativo (Pinecone/Qdrant). Raccomandato mantenere Voiceflow KB nella prima iterazione per ridurre scope.
3. **Frontend**: Il webchat attuale usa il widget Voiceflow. Nella migrazione serve un nuovo frontend o un adattatore webhook — da definire separatamente (out of scope di questo piano).
