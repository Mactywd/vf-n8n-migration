# Setup Credenziali n8n per Alchimista NdC

## Scopo

Questo documento fornisce istruzioni passo-passo per configurare le credenziali necessarie in n8n (istanza Hetzner) per la migrazione del workflow Voiceflow dell'applicazione Alchimista NdC.

Le credenziali consentono a n8n di:
- Accedere al Knowledge Base di Voiceflow per cercare essenze di profumi
- Utilizzare l'API Claude di Anthropic per le risposte conversazionali
- Leggere e scrivere lo stato della sessione su Supabase

---

## Credenziali Necessarie

### 1. Voiceflow KB API

**Tipo n8n:** Custom HTTP Header Auth

**Scopo:** Autenticazione per le chiamate al Knowledge Base API di Voiceflow per cercare essenze di profumi.

**Campi da compilare:**

| Campo | Valore |
|-------|--------|
| **Nome credential** | `Voiceflow KB API` |
| **Header name** | `Authorization` |
| **Header value** | `Bearer <API_KEY_VOICEFLOW>` |

**Come trovare il valore:**

1. Accedi alla **dashboard Voiceflow** (https://creator.voiceflow.com)
2. Seleziona il progetto **Alchimista NdC**
3. Vai a **Settings** (Impostazioni) → **API Keys** (Chiavi API)
4. Copia la chiave API principale (se non presente, genera una nuova)
5. Incolla il valore nel campo **Header value** come `Bearer <VALORE_COPIATO>`

**Dove viene usata:**

- **HTTP Request node** che effettua chiamate a `https://general-runtime.voiceflow.com/knowledge-base/query`
- Payload tipico:
  ```json
  {
    "query": "Nome: Meriggio",
    "documentId": "687f99a3854389cf5efea956"
  }
  ```

**Note importanti:**

- La documentId è fissa: `687f99a3854389cf5efea956` (Knowledge Base Voiceflow di Alchimista NdC)
- L'API consente di cercare essenze per nome, categoria o descrizione libera
- Le risposte ritornano fino a 10 chunk per ricerca, supportando paginazione

---

### 2. Anthropic API (Claude)

**Tipo n8n:** Anthropic (credential nativa n8n)

**Scopo:** Autenticazione per i nodi AI Agent e AI LLM che generano risposte conversazionali tramite Claude.

**Campi da compilare:**

| Campo | Valore |
|-------|--------|
| **Nome credential** | `Anthropic Claude` |
| **API Key** | `<TUA_ANTHROPIC_API_KEY>` |

**Come trovare il valore:**

1. Accedi alla **console Anthropic** (https://console.anthropic.com)
2. Vai a **API Keys** (Chiavi API) nel menu laterale
3. Clicca su **Create Key** (Crea Chiave)
4. Assegna un nome descrittivo (es. "Alchimista NdC - n8n")
5. Copia la chiave completa (inizia con `sk-ant-`)
6. Incolla nel campo **API Key**

**Dove viene usata:**

- **AI Agent nodes** per il Routing Agent, Sorting Agent, Memory Extraction Agent, etc.
- **AI LLM nodes** per generare testo (descrizioni poesia, suggerimenti essenze)
- Modello consigliato: `claude-3-5-sonnet` (equilibrio qualità/costo)

**Note importanti:**

- Ogni agente del workflow usa questa stessa credenziale
- N8n supporta nativamente i modelli Claude con parameter cache (consigliato per prompt lunghi)
- Quota API: configura limiti nel dashboard Anthropic per evitare overspend

---

### 3. Supabase (Session Store)

**Tipo n8n:** Supabase (credential nativa n8n) *oppure* Custom HTTP Header Auth

**Scopo:** Lettura e scrittura della tabella di sessione che persiste lo stato della conversazione (essenze selezionate, memoria utente, preferenze).

**Opzione A: Credential Supabase Nativa (Consigliato)**

| Campo | Valore |
|-------|--------|
| **Nome credential** | `Supabase Session Store` |
| **Project URL** | `https://<YOUR_PROJECT_REF>.supabase.co` |
| **Service Role Key** | `<SERVICE_ROLE_KEY>` |

**Opzione B: Custom HTTP Header Auth (se credential nativa non disponibile)**

| Campo | Valore |
|-------|--------|
| **Nome credential** | `Supabase HTTP Auth` |
| **Header name** | `Authorization` |
| **Header value** | `Bearer <SERVICE_ROLE_KEY>` |

**Come trovare i valori:**

1. Accedi a **Supabase** (https://supabase.com)
2. Seleziona il progetto Alchimista NdC
3. Vai a **Settings** (Impostazioni) → **API**
4. Copia:
   - **Project URL** (es. `https://abc123def456.supabase.co`)
   - **Service Role Key** (NOT la chiave anonima) — è sotto "Service role secret"
5. Incolla i valori nei campi corrispondenti

**Dove viene usata:**

- **Supabase Query node** (o HTTP Request node) per leggere sessioni esistenti
- **Supabase Insert/Update node** per salvare lo stato della conversazione
- Tabella target: `sessions` (schema: user_id, session_data, essences_selected, created_at, updated_at)

**Note importanti:**

- **Usa sempre Service Role Key, non la chiave anonima** — serve per operazioni senza RLS
- Supabase supporta paginazione; configura nel nodo per grandi volumi di dati
- La sessione può includere: `{ user_id, target_gender, perfume_memory, selectedChunks[], perfume_name, ... }`

---

## Procedura di Configurazione in n8n

### Step 1: Accedere al Menu Credenziali

1. Accedi all'istanza n8n su **Hetzner** (URL fornito dal team)
2. Clicca sull'icona **Credentials** (chiave) nel menu laterale sinistro
3. Clicca sul pulsante **+ New** (in alto a destra)

### Step 2: Creare Voiceflow KB API

1. Seleziona **Type**: ricerca "HTTP Header Auth" oppure "Custom Header"
2. Compila i campi:
   - **Name**: `Voiceflow KB API`
   - **Header name**: `Authorization`
   - **Header value**: `Bearer <API_KEY_VOICEFLOW>`
3. Clicca **Save**

### Step 3: Creare Anthropic API

1. Clicca **+ New**
2. Seleziona **Type**: ricerca "Anthropic" (dovrebbe essere una credential nativa)
3. Compila i campi:
   - **Name**: `Anthropic Claude`
   - **API Key**: `<TUA_ANTHROPIC_API_KEY>`
4. Clicca **Save**

### Step 4: Creare Supabase

1. Clicca **+ New**
2. Seleziona **Type**: ricerca "Supabase"
   - Se non disponibile, usa "HTTP Header Auth" con configurazione alternativa
3. Compila i campi:
   - **Name**: `Supabase Session Store`
   - **Project URL**: `https://<YOUR_PROJECT_REF>.supabase.co`
   - **Service Role Key**: `<SERVICE_ROLE_KEY>`
4. Clicca **Save**

---

## Verifica delle Credenziali

### Verifica 1: Voiceflow KB API

1. Crea un nuovo **workflow di test** in n8n
2. Aggiungi un nodo **HTTP Request**:
   - **Method**: `POST`
   - **URL**: `https://general-runtime.voiceflow.com/knowledge-base/query`
   - **Authentication**: seleziona `Voiceflow KB API`
   - **Body** (raw JSON):
     ```json
     {
       "query": "Nome: Meriggio",
       "documentId": "687f99a3854389cf5efea956",
       "limit": 2
     }
     ```
3. Clicca **Test step** (Play icon)
4. **Risultato atteso**: Array di chunk con essenza "Meriggio" (id, nome, descrizione, categoria)
5. Se ottieni `401 Unauthorized` → API Key errata o formato non corretto
6. Se ottieni `404 Not Found` → URL o documentId errati

### Verifica 2: Anthropic API

1. Aggiungi un nodo **AI - LLM** (nativo n8n):
   - **Credential**: seleziona `Anthropic Claude`
   - **Model**: `claude-3-5-sonnet-20241022`
   - **Prompt**: `Sei L'Alchimista del Chianti. Saluta l'utente in italiano con una frase mistica.`
3. Clicca **Test step**
4. **Risultato atteso**: Una risposta in italiano con tono mistico
5. Se ottieni `401 Unauthorized` → API Key errata
6. Se ottieni `rate_limit_error` → Quota superata (controlla dashboard Anthropic)

### Verifica 3: Supabase

1. Aggiungi un nodo **HTTP Request**:
   - **Method**: `GET`
   - **URL**: `https://<YOUR_PROJECT_REF>.supabase.co/rest/v1/sessions?limit=1`
   - **Headers** (aggiungi manualmente):
     - `apikey`: `<SUPABASE_ANON_KEY>` (per lettura pubblica)
     - `Authorization`: `Bearer <SERVICE_ROLE_KEY>` (per lettura con RLS bypass)
   - **Response Format**: `JSON`
2. Clicca **Test step**
3. **Risultato atteso**: Array di sessioni (può essere vuoto se nessuna sessione salvata)
4. Se ottieni `401 Unauthorized` → Service Role Key errata
5. Se ottieni `404 Not Found` → Project URL o nome tabella errati

**Alternativa (con credential Supabase nativa):**

1. Aggiungi un nodo **Supabase > Read** (se disponibile):
   - **Credential**: seleziona `Supabase Session Store`
   - **Table**: `sessions`
   - **Query**: (lascia vuoto per leggere tutte)
2. Clicca **Test step**
3. **Risultato atteso**: Stesse risposte della verifica HTTP

---

## Troubleshooting

| Errore | Causa | Soluzione |
|--------|-------|-----------|
| `401 Unauthorized` | Credenziale non valida o scaduta | Rigenera la chiave API nel servizio corrispondente |
| `403 Forbidden` | Permessi insufficienti | Per Supabase, assicura di usare **Service Role Key**, non anonima |
| `ECONNREFUSED` | Servizio non raggiungibile | Controlla URL, proxy, firewall; verifica connettività da Hetzner |
| `timeout` | Richiesta troppo lenta | Aumenta timeout nel nodo (campo **Request timeout**); controlla banda |
| `Invalid JSON` | Payload malformato | Valida il JSON con un linter (es. jsonlint.com) |

---

## Checklist di Completamento

- [ ] Voiceflow KB API credential creata e testata
- [ ] Anthropic Claude API credential creata e testata
- [ ] Supabase credential creata e testata
- [ ] Tutte e tre le credenziali visibili nella lista **Credentials** → **All**
- [ ] Nome di ciascuna credential corrisponde al suggerito nel documento
- [ ] Ogni credential passa il test di verifica
- [ ] Documenta i nomi esatti delle credential in un file di configurazione locale (per il team)

---

## Prossimi Step

Una volta verificate tutte le credenziali:

1. Creare i **nodi HTTP Request** nei workflow per consumare le API
2. Configurare i **nodi AI Agent** con la credential Anthropic
3. Implementare la **logica di persistenza sessione** con Supabase
4. Testare il workflow end-to-end con un utente di prova

