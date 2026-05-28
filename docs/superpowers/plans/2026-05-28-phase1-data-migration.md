# Phase 1: Data Migration (Voiceflow KB → Directus + Qdrant) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Export all 90 essences from the Voiceflow Knowledge Base and import them into Directus (as structured records) and Qdrant (as vector embeddings for semantic search).

**Architecture:** Python migration script reads from Voiceflow KB API → parses semicolon-delimited content → imports to Directus → triggers n8n re-index hook to embed and push to Qdrant.

**Tech Stack:** Python 3, Voiceflow KB API, Directus REST API, n8n workflow for embedding + Qdrant indexing

**Depends on:** Phase 0 (Directus and Qdrant must be running, collection created)  
**Required by:** Phase 2 (kb-search sub-workflow needs data in Qdrant)

---

## Reference: Voiceflow KB chunk format

Each chunk returned by the Voiceflow KB API has this `content` field:

```
Categoria: Marina; Nome: Accord Macchia Mediterranea; Contenuto: Aromatico, Balsamico; Contenuto_en: Aromatic, Balsamic; Descrizione: Accordo aromatico che...; Tipo: Testa; Immagine: https://...
```

The migration script parses this into structured fields.

---

## Task 1: Export all chunks from Voiceflow KB

**Files:**
- Create: `scripts/export_voiceflow_kb.py`

- [ ] **Step 1: Create the export script**

```python
#!/usr/bin/env python3
"""Export all chunks from the Voiceflow Knowledge Base."""

import json
import requests

VOICEFLOW_API_KEY = "VF.DM.687f9621…"  # from alchimista.json variable api_key
DOCUMENT_ID = "687f99a3854389cf5efea956"
OUTPUT_FILE = "scripts/voiceflow_chunks_raw.json"

def fetch_all_chunks():
    """Query the KB with a broad query to get all chunks."""
    url = "https://general-runtime.voiceflow.com/knowledge-base/query"
    headers = {"Authorization": VOICEFLOW_API_KEY}
    
    # Use a very broad query to get all essences
    # Run multiple queries with different category terms to maximize coverage
    queries = [
        "essenza profumo",
        "categoria marina legnosa",
        "categoria floreale agrumata",
        "categoria orientale muschiata speziata",
        "categoria verde erbacea",
    ]
    
    all_chunks = {}  # keyed by chunkID to deduplicate
    
    for query in queries:
        payload = {
            "chunkLimit": 20,
            "synthesis": False,
            "settings": {"model": "claude-3-haiku", "temperature": 0},
            "query": query
        }
        resp = requests.post(url, headers=headers, json=payload)
        resp.raise_for_status()
        data = resp.json()
        for chunk in data.get("chunks", []):
            all_chunks[chunk["chunkID"]] = chunk
        print(f"Query '{query}': {len(data.get('chunks', []))} chunks, total unique: {len(all_chunks)}")
    
    return list(all_chunks.values())

if __name__ == "__main__":
    chunks = fetch_all_chunks()
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(chunks, f, ensure_ascii=False, indent=2)
    print(f"\nSaved {len(chunks)} chunks to {OUTPUT_FILE}")
```

- [ ] **Step 2: Run the export**

```bash
cd /home/mattia/coding/ais/goldenhour/migration
pip install requests
python3 scripts/export_voiceflow_kb.py
```

Expected: `Saved N chunks to scripts/voiceflow_chunks_raw.json` where N is 80-90.

- [ ] **Step 3: Inspect the raw output**

```bash
python3 -c "
import json
data = json.load(open('scripts/voiceflow_chunks_raw.json'))
print(f'Total chunks: {len(data)}')
print('First chunk content:')
print(data[0]['content'][:300])
"
```

Verify the content field has the semicolon-delimited format.

---

## Task 2: Parse and import to Directus

**Files:**
- Create: `scripts/import_to_directus.py`

- [ ] **Step 1: Create the import script**

```python
#!/usr/bin/env python3
"""Parse Voiceflow chunks and import to Directus."""

import json
import requests

DIRECTUS_URL = "http://localhost:8055"
DIRECTUS_TOKEN = "<your-directus-token>"
INPUT_FILE = "scripts/voiceflow_chunks_raw.json"

def parse_content(content: str) -> dict:
    """Parse semicolon-delimited content string into a dict."""
    result = {}
    for pair in content.split(";"):
        pair = pair.strip()
        if not pair:
            continue
        colon_idx = pair.index(":") if ":" in pair else -1
        if colon_idx == -1:
            continue
        key = pair[:colon_idx].strip()
        value = pair[colon_idx + 1:].strip()
        result[key] = value
    return result

def import_chunks(chunks: list):
    headers = {
        "Authorization": f"Bearer {DIRECTUS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    imported = 0
    errors = 0
    
    for chunk in chunks:
        parsed = parse_content(chunk["content"])
        
        # Skip chunks with no name
        if not parsed.get("Nome"):
            print(f"Skipping chunk {chunk['chunkID']}: no Nome field")
            continue
        
        # Parse immagini: may be a single URL string or comma-separated
        immagini_raw = parsed.get("Immagine", "")
        immagini = [u.strip() for u in immagini_raw.split(",") if u.strip()]
        
        record = {
            "nome": parsed.get("Nome", ""),
            "categoria": parsed.get("Categoria", ""),
            "contenuto_it": parsed.get("Contenuto", ""),
            "contenuto_en": parsed.get("Contenuto_en", ""),
            "descrizione": parsed.get("Descrizione", ""),
            "tipo": parsed.get("Tipo", ""),
            "immagini": immagini,
            "voiceflow_chunk_id": chunk["chunkID"]  # keep for reference
        }
        
        resp = requests.post(
            f"{DIRECTUS_URL}/items/essenze",
            headers=headers,
            json=record
        )
        
        if resp.status_code in (200, 201):
            imported += 1
            print(f"✓ {record['nome']}")
        else:
            errors += 1
            print(f"✗ {record['nome']}: {resp.status_code} {resp.text[:100]}")
    
    print(f"\nImported: {imported}, Errors: {errors}")

if __name__ == "__main__":
    chunks = json.load(open(INPUT_FILE))
    import_chunks(chunks)
```

> **Note:** If the `voiceflow_chunk_id` field doesn't exist in the Directus collection, add it first:
> ```bash
> curl -X POST http://localhost:8055/fields/essenze \
>   -H "Authorization: Bearer $DIRECTUS_TOKEN" \
>   -H "Content-Type: application/json" \
>   -d '{"field": "voiceflow_chunk_id", "type": "string"}'
> ```

- [ ] **Step 2: Run the import**

```bash
python3 scripts/import_to_directus.py
```

Expected: ~90 lines of `✓ <nome essenza>`, `Imported: 90, Errors: 0`.

- [ ] **Step 3: Verify in Directus**

```bash
curl -s "http://localhost:8055/items/essenze?limit=5" \
  -H "Authorization: Bearer $DIRECTUS_TOKEN" | python3 -m json.tool
```

Expected: 5 records with all fields populated.

```bash
curl -s "http://localhost:8055/items/essenze?aggregate[count]=id" \
  -H "Authorization: Bearer $DIRECTUS_TOKEN"
```

Expected: `{"data": [{"count": {"id": "90"}}]}` (approximately).

---

## Task 3: Build the Directus → Qdrant indexing workflow in n8n

**Files:** n8n workflow (created via REST API)

This n8n workflow:
1. Receives a Directus essenza record (via webhook or Execute Workflow trigger)
2. Builds a text string for embedding from the record fields
3. Calls an embedding model (via OpenRouter or OpenAI) to get the vector
4. Upserts the vector + metadata into Qdrant

- [ ] **Step 1: Create the workflow JSON**

Save as `workflows/index-essenza-qdrant.json`:

```json
{
  "name": "index-essenza-qdrant",
  "nodes": [
    {
      "name": "Execute Workflow Trigger",
      "type": "n8n-nodes-base.executeWorkflowTrigger",
      "position": [250, 300],
      "parameters": {}
    },
    {
      "name": "Build Embedding Text",
      "type": "n8n-nodes-base.code",
      "position": [450, 300],
      "parameters": {
        "jsCode": "const e = $input.first().json;\nconst text = [\n  `Categoria: ${e.categoria}`,\n  `Nome: ${e.nome}`,\n  `Contenuto: ${e.contenuto_it}`,\n  `Descrizione: ${e.descrizione}`,\n  `Tipo: ${e.tipo}`\n].filter(Boolean).join('; ');\nreturn [{ json: { ...e, embedding_text: text } }];"
      }
    },
    {
      "name": "Get Embedding",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 300],
      "parameters": {
        "method": "POST",
        "url": "https://openrouter.ai/api/v1/embeddings",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "openAiApi",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {"name": "model", "value": "openai/text-embedding-3-small"},
            {"name": "input", "value": "={{ $json.embedding_text }}"}
          ]
        }
      }
    },
    {
      "name": "Upsert to Qdrant",
      "type": "n8n-nodes-base.httpRequest",
      "position": [850, 300],
      "parameters": {
        "method": "PUT",
        "url": "http://qdrant:6333/collections/essenze/points",
        "sendBody": true,
        "contentType": "json",
        "body": "={{ JSON.stringify({ points: [{ id: $('Execute Workflow Trigger').first().json.id, vector: $json.data[0].embedding, payload: { nome: $('Execute Workflow Trigger').first().json.nome, categoria: $('Execute Workflow Trigger').first().json.categoria, contenuto_it: $('Execute Workflow Trigger').first().json.contenuto_it, contenuto_en: $('Execute Workflow Trigger').first().json.contenuto_en, descrizione: $('Execute Workflow Trigger').first().json.descrizione, tipo: $('Execute Workflow Trigger').first().json.tipo, immagini: $('Execute Workflow Trigger').first().json.immagini } }] }) }}"
      }
    }
  ],
  "connections": {
    "Execute Workflow Trigger": {"main": [[{"node": "Build Embedding Text"}]]},
    "Build Embedding Text": {"main": [[{"node": "Get Embedding"}]]},
    "Get Embedding": {"main": [[{"node": "Upsert to Qdrant"}]]}
  }
}
```

- [ ] **Step 2: Deploy the workflow**

```bash
N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwNzQ2M2JlNy1jZmE1LTQzNTctYTNlOS0wMjE0NmMyYTZhMWEiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzc5NTI5MzY0fQ.3iX6kwwSE5KJOErF2mahMtUOQ5b5-m9_aCgO8dY4uzM"
N8N_BASE_URL="https://n8n.mattiagirellini.com"

curl -s -X POST "$N8N_BASE_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/index-essenza-qdrant.json | python3 -m json.tool
```

Note the returned `id` — this is `INDEX_WORKFLOW_ID`.

---

## Task 4: Bulk index all essences to Qdrant

**Files:**
- Create: `scripts/bulk_index_qdrant.py`

- [ ] **Step 1: Create the bulk indexing script**

```python
#!/usr/bin/env python3
"""Trigger n8n index-essenza-qdrant for every record in Directus."""

import requests
import time

DIRECTUS_URL = "http://localhost:8055"
DIRECTUS_TOKEN = "<your-directus-token>"
N8N_BASE_URL = "https://n8n.mattiagirellini.com"
N8N_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
INDEX_WORKFLOW_ID = "<id-from-task-3-step-2>"

def get_all_essenze():
    resp = requests.get(
        f"{DIRECTUS_URL}/items/essenze?limit=200",
        headers={"Authorization": f"Bearer {DIRECTUS_TOKEN}"}
    )
    resp.raise_for_status()
    return resp.json()["data"]

def trigger_index(essenza: dict):
    resp = requests.post(
        f"{N8N_BASE_URL}/api/v1/workflows/{INDEX_WORKFLOW_ID}/run",
        headers={"X-N8N-API-KEY": N8N_API_KEY, "Content-Type": "application/json"},
        json={"workflowData": {"pinData": {}}, "startNodes": [], "runData": None, "inputData": {"main": [[essenza]]}}
    )
    return resp.status_code in (200, 201)

if __name__ == "__main__":
    essenze = get_all_essenze()
    print(f"Indexing {len(essenze)} essenze...")
    
    for i, e in enumerate(essenze):
        ok = trigger_index(e)
        status = "✓" if ok else "✗"
        print(f"{status} [{i+1}/{len(essenze)}] {e['nome']}")
        time.sleep(0.5)  # avoid overwhelming the embedding API
    
    print("Done.")
```

- [ ] **Step 2: Run bulk indexing**

```bash
python3 scripts/bulk_index_qdrant.py
```

Expected: all essences indexed with `✓`.

- [ ] **Step 3: Verify Qdrant collection count**

```bash
curl -s http://localhost:6333/collections/essenze | python3 -m json.tool
```

Expected: `"points_count"` equals the number of imported Directus records (~90).

- [ ] **Step 4: Test a semantic search**

```bash
curl -s -X POST http://localhost:6333/collections/essenze/points/search \
  -H "Content-Type: application/json" \
  -d '{
    "vector": null,
    "limit": 3,
    "with_payload": true,
    "query": "marina salmastro mediterraneo"
  }' | python3 -m json.tool
```

> **Note:** This uses Qdrant's sparse/keyword search for verification. Vector search requires an actual embedding vector — test that in Phase 2 when the kb-search sub-workflow is built.

---

## Task 5: Set up Directus → Qdrant auto-hook

**Files:** n8n workflow (created via REST API)

When an essence is created/updated in Directus, automatically re-index it in Qdrant.

- [ ] **Step 1: Create the Directus webhook in n8n**

In n8n: create a new workflow named `directus-reindex-hook`:
- **Trigger:** Webhook node (POST method)
- Get the webhook URL after saving (e.g., `https://n8n.mattiagirellini.com/webhook/directus-reindex`)
- **Next node:** Execute Workflow node → calls `index-essenza-qdrant` with `$json.payload` as input

- [ ] **Step 2: Register the webhook in Directus**

```bash
curl -s -X POST "http://localhost:8055/webhooks" \
  -H "Authorization: Bearer $DIRECTUS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Reindex on Qdrant",
    "method": "POST",
    "url": "https://n8n.mattiagirellini.com/webhook/directus-reindex",
    "status": "active",
    "collections": ["essenze"],
    "actions": ["create", "update"]
  }'
```

- [ ] **Step 3: Activate the n8n hook workflow**

```bash
curl -s -X POST "$N8N_BASE_URL/api/v1/workflows/<directus-reindex-hook-id>/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

- [ ] **Step 4: Test the hook end-to-end**

Update an essenza in Directus:
```bash
curl -s -X PATCH "http://localhost:8055/items/essenze/1" \
  -H "Authorization: Bearer $DIRECTUS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"contenuto_it": "Aromatico, Balsamico, Con sentori di mirto"}'
```

Check n8n execution logs — the `directus-reindex-hook` workflow should have triggered.

---

## Phase 1 Complete — Verification Checklist

- [ ] `scripts/voiceflow_chunks_raw.json` exists with ~90 chunks
- [ ] ~90 essenze records in Directus `essenze` collection
- [ ] ~90 vectors in Qdrant `essenze` collection
- [ ] `index-essenza-qdrant` n8n workflow deployed and working
- [ ] `directus-reindex-hook` n8n workflow active — updates in Directus auto-sync to Qdrant
