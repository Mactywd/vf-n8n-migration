# Alchimista NdC — Compromessi architetturali e modifiche infrastrutturali

**Data:** 2026-05-28

Questo documento descrive (1) i compromessi inevitabili imposti dall'architettura n8n rispetto a Voiceflow, e (2) tutte le modifiche necessarie al di fuori dei workflow n8n stessi.

---

## Parte 1 — Compromessi architetturali

### 1. Nessun token streaming

**Voiceflow:** il testo AI appare lettera per lettera mentre il modello genera.  
**n8n:** risposta completa inviata al termine dell'esecuzione. L'utente vede un typing indicator, poi il testo appare tutto insieme.

**Impatto UX:** percepibile ma accettabile. Il typing indicator compensa parzialmente. Aggiungere streaming reale in futuro richiederà un gateway SSE esterno senza toccare la logica n8n.

---

### 2. Stateless execution — sessione esterna obbligatoria

**Voiceflow:** lo stato conversazionale (selectedChunks, perfume_memory, ecc.) vive in memoria durante tutta la conversazione.  
**n8n:** ogni esecuzione è completamente isolata. Lo stato deve essere caricato da Postgres a inizio turno e salvato a fine turno.

**Impatto:** due chiamate DB aggiuntive per ogni turno (session-read + session-write). Su Hetzner con Postgres locale la latenza è < 5ms — trascurabile.

**Rischio:** se n8n crasha a metà esecuzione dopo session-read ma prima di session-write, lo stato non viene aggiornato e il turno va perso. Mitigazione: il frontend può ri-inviare il messaggio — l'utente vede al massimo un "timeout" e ritenta.

---

### 3. Timeout HTTP — nginx configurato a 120s

**Voiceflow:** nessun timeout lato protocollo (connessione SSE persistente).  
**n8n:** risposta sincrona — la connessione HTTP deve rimanere aperta per tutta la durata dell'esecuzione.

**Impatto:** se una chiamata AI o KB search supera 120s (improbabile ma possibile sotto carico), il frontend riceve un errore di timeout senza risposta. Il frontend deve gestire questo caso con retry automatico o messaggio di errore esplicito.

---

### 4. Routing AI — output paths impliciti

**Voiceflow:** gli agenti hanno output paths espliciti cablati visualmente nel flow editor (es. "Route to Memory", "Route to Inspiration"). Il motore di routing è deterministico.  
**n8n:** l'AI Agent genera testo libero. La decisione di routing deve essere estratta dall'output dell'agente (parsing JSON strutturato, o campo dedicato come `{ "path": "memory" }`).

**Impatto:** gli agenti che prendono decisioni di routing (Routing Agent, Sorting Agent, Memory Extraction Agent) devono essere configurati con un system prompt che impone output strutturato. Esempio:

```
Rispondi SEMPRE in formato JSON:
{
  "message": "testo per l'utente",
  "path": "memory" | "inspiration" | "renaissance"
}
```

Il Code node successivo estrae `path` e alimenta un Switch node. Questo è un pattern consolidato in n8n ma richiede attenzione nel prompt engineering.

---

### 5. Buttons e Carousel — rendering delegato al frontend

**Voiceflow:** bottoni e carousel sono tipi nativi del widget Voiceflow, renderizzati automaticamente.  
**n8n:** il workflow restituisce strutture JSON (`buttons[]`, `carousel`). Il frontend deve implementare il rendering di questi componenti.

**Impatto:** lavoro frontend aggiuntivo. I componenti devono rispettare la struttura definita nel payload API (vedi design spec).

---

### 6. KB Search — latenza Qdrant vs Voiceflow KB nativa

**Voiceflow:** la KB è co-locata con il runtime, lookup ottimizzato.  
**n8n:** Qdrant su Hetzner, chiamata HTTP interna. L'agente KB può fare più ricerche in autonomia.

**Impatto:** latenza aggiuntiva stimata 50-200ms per ricerca Qdrant. Con l'agente AI che gestisce query e valutazione, un ciclo KB completo può richiedere 3-8s. Accettabile per un'esperienza conversazionale (l'utente si aspetta qualche secondo di attesa).

---

### 7. Sessioni abbandonate — cleanup necessario

**Voiceflow:** la sessione scade automaticamente.  
**n8n:** le righe nella tabella `sessions` persistono indefinitamente senza cleanup.

**Impatto:** la tabella cresce nel tempo. Serve un workflow schedulato (cron) che elimina sessioni con `updated_at` più vecchio di N ore (es. 24h). Da implementare come workflow utility separato.

---

## Parte 2 — Modifiche infrastrutturali (VPS Hetzner)

### 2.1 Postgres — tabella sessions

**Azione:** aggiungere la tabella `sessions` al DB Postgres esistente di n8n.

```sql
CREATE TABLE sessions (
  id          TEXT PRIMARY KEY,
  state       JSONB NOT NULL DEFAULT '{}',
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_sessions_updated_at ON sessions (updated_at);
```

**Come:** accesso diretto al container Postgres di n8n, o tramite il nodo Postgres di n8n con query SQL diretta.

---

### 2.2 Qdrant — installazione e configurazione

**Azione:** installare Qdrant sul server Hetzner.

**Opzioni:**
- Docker container (raccomandato — già presente Docker per n8n)
- Binario standalone

**Configurazione minima `docker-compose` (aggiunta al compose esistente):**
```yaml
qdrant:
  image: qdrant/qdrant:latest
  ports:
    - "6333:6333"
  volumes:
    - qdrant_data:/qdrant/storage
```

**Collection da creare:** `essenze` con dimensione vettore compatibile con il modello di embedding scelto (es. 1536 per OpenAI text-embedding-3-small, 768 per altri).

---

### 2.3 Directus — verifica o installazione

**Azione:** verificare se Directus è già installato (dal workflow "CMS to Vector Store Hook" già presente su n8n). Se non configurato, installare come container Docker.

**Struttura collection Directus `essenze`:**

| Campo | Tipo | Descrizione |
|---|---|---|
| `nome` | string | Nome essenza |
| `categoria` | string | Categoria (Marina, Legnosa, ecc.) |
| `contenuto_it` | text | Descrizione italiana breve |
| `contenuto_en` | text | Descrizione inglese breve |
| `descrizione` | text | Descrizione estesa |
| `tipo` | string | Testa / Cuore / Fondo |
| `immagini` | array | URL immagini per carousel |

**Hook Directus → Qdrant:** quando un'essenza viene creata/modificata/eliminata in Directus, un webhook chiama un workflow n8n che re-indicizza l'essenza su Qdrant.

---

### 2.4 Migrazione dati — Voiceflow KB → Directus + Qdrant

**Azione:** estrarre le 90 essenze dalla Voiceflow KB e importarle in Directus.

**Processo:**
1. Esportare i chunk dalla Voiceflow KB via API (Document ID: `687f99a3854389cf5efea956`)
2. Parsare il formato `Categoria: X; Nome: Y; Contenuto: Z; ...`
3. Importare in Directus via API REST
4. Triggerare re-index completo su Qdrant

---

### 2.5 nginx — timeout configurazione

**Azione:** modificare la configurazione nginx del reverse proxy davanti a n8n.

**File:** tipicamente `/etc/nginx/sites-available/n8n` o equivalente.

**Aggiungere nel blocco `location`:**
```nginx
proxy_read_timeout 120s;
proxy_send_timeout 120s;
proxy_connect_timeout 10s;
```

---

### 2.6 n8n — credenziali da configurare

| Credenziale | Tipo | Usata da |
|---|---|---|
| OpenRouter API Key | HTTP Header Auth | Tutti gli AI Agent node |
| Postgres (sessions) | Postgres | session-read, session-write |
| Qdrant | HTTP (localhost:6333) | Sub-workflow kb-search |
| Directus API | HTTP Header Auth | Hook re-index Qdrant |
| Exa.ai API Key | HTTP Header Auth | Inspiration path (api-v2 node) |

---

## Parte 3 — Modifiche frontend

### 3.1 Rimozione Voiceflow SDK

**Azione:** rimuovere completamente il widget Voiceflow e tutte le relative dipendenze (`@voiceflow/chat-widget` o equivalente).

---

### 3.2 Nuova logica di comunicazione

**Sostituisce:** SSE Voiceflow  
**Con:** POST sincrono + gestione risposta JSON

```typescript
async function sendMessage(sessionId: string, message: string) {
  const response = await fetch('/webhook/root', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ session_id: sessionId, message }),
    signal: AbortSignal.timeout(115_000) // leggermente sotto i 120s nginx
  });
  return response.json(); // { message, buttons?, carousel?, current_step }
}
```

---

### 3.3 Gestione session_id

**Azione:** generare e persistere un `session_id` lato frontend.

```typescript
function getSessionId(): string {
  let id = localStorage.getItem('alchimista_session_id');
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem('alchimista_session_id', id);
  }
  return id;
}
```

---

### 3.4 Nuovi componenti UI da implementare

| Componente | Descrizione |
|---|---|
| Typing indicator | Mostrato mentre si attende la risposta (POST in corso) |
| Button group | Renderizza `buttons[]` come bottoni cliccabili |
| Carousel | Renderizza `carousel.cards[]` con immagine, titolo, descrizione, bottone selezione |
| Error handling | Gestisce timeout (115s), errori HTTP, e risposta vuota |

---

### 3.5 Reset sessione

**Azione:** aggiungere un modo per resettare la sessione (nuovo `session_id` → nuova conversazione).

```typescript
function resetSession() {
  localStorage.removeItem('alchimista_session_id');
  // reload o redirect
}
```
