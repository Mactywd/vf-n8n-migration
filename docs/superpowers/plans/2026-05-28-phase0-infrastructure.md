# Phase 0: Infrastructure Setup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare all server-side infrastructure required before any n8n workflow can be built.

**Architecture:** Postgres sessions table in n8n's existing DB, Qdrant as Docker container, Directus verified/installed, nginx timeout raised, all n8n credentials configured.

**Tech Stack:** PostgreSQL, Docker/Docker Compose, Qdrant, Directus, nginx, n8n REST API

**Depends on:** nothing — this is the first phase.  
**Required by:** Phase 1 (Data Migration), Phase 2 (Utility Workflows)

---

## Task 0: Verify current server state

**Files:** none

- [ ] **Step 1: Check running Docker containers**

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

Expected: see n8n and Postgres containers. Note the Postgres container name.

- [ ] **Step 2: Find the docker-compose file**

```bash
find / -name "docker-compose*.yml" 2>/dev/null | grep -v proc
```

Note the path — you'll modify this file in Task 2.

- [ ] **Step 3: Check if Directus is already running**

```bash
docker ps | grep directus
```

If present, note the URL and API key. If absent, Task 3 will install it.

- [ ] **Step 4: Check if Qdrant is already running**

```bash
docker ps | grep qdrant
curl -s http://localhost:6333/healthz
```

If `{"title":"qdrant - healthy"}` returns, skip Task 2. Otherwise proceed.

---

## Task 1: Create sessions table in Postgres

**Files:** none (direct DB operation)

- [ ] **Step 1: Connect to the Postgres container**

```bash
docker exec -it <postgres-container-name> psql -U <n8n-db-user> -d <n8n-db-name>
```

To find the correct values, check the n8n container's environment:
```bash
docker inspect <n8n-container-name> | grep -E "DB_POSTGRESDB|POSTGRES"
```

- [ ] **Step 2: Create the sessions table**

Run inside psql:
```sql
CREATE TABLE IF NOT EXISTS sessions (
  id          TEXT PRIMARY KEY,
  state       JSONB NOT NULL DEFAULT '{}',
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_updated_at ON sessions (updated_at);
```

- [ ] **Step 3: Verify the table exists**

```sql
\d sessions
```

Expected output: table with columns `id`, `state`, `updated_at`.

- [ ] **Step 4: Insert and read a test row**

```sql
INSERT INTO sessions (id, state) VALUES ('test-session-1', '{"current_step": "init"}');
SELECT * FROM sessions WHERE id = 'test-session-1';
DELETE FROM sessions WHERE id = 'test-session-1';
```

Expected: insert succeeds, select returns the row, delete succeeds.

- [ ] **Step 5: Exit psql**

```sql
\q
```

---

## Task 2: Add Qdrant to Docker Compose

**Files:** Modify the existing `docker-compose.yml`

- [ ] **Step 1: Open docker-compose.yml**

```bash
cat <path-to-docker-compose.yml>
```

Note the existing `volumes:` top-level section and `networks:` if present.

- [ ] **Step 2: Add Qdrant service**

Add the following to the `services:` section:

```yaml
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_storage:/qdrant/storage
```

Add to the top-level `volumes:` section:

```yaml
  qdrant_storage:
```

- [ ] **Step 3: Start Qdrant**

```bash
docker compose up -d qdrant
```

- [ ] **Step 4: Verify Qdrant is healthy**

```bash
curl -s http://localhost:6333/healthz
```

Expected: `{"title":"qdrant - healthy"}`

- [ ] **Step 5: Create the essences collection**

```bash
curl -s -X PUT http://localhost:6333/collections/essenze \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'
```

Expected: `{"result":true,"status":"ok","time":...}`

> **Note on vector size:** 1536 is for OpenAI `text-embedding-3-small`. If using a different embedding model via OpenRouter/Directus, adjust the size accordingly.

- [ ] **Step 6: Verify collection exists**

```bash
curl -s http://localhost:6333/collections/essenze | python3 -m json.tool
```

Expected: JSON with `"status": "green"` and `"vectors_count": 0`.

---

## Task 3: Verify or install Directus

**Files:** Modify `docker-compose.yml` if Directus is not present

- [ ] **Step 1: Check if Directus is already running (from Task 0)**

If Directus was found in Task 0 Step 3, skip to Step 5.

- [ ] **Step 2: Add Directus to docker-compose.yml**

Add to `services:`:

```yaml
  directus:
    image: directus/directus:latest
    container_name: directus
    restart: unless-stopped
    ports:
      - "8055:8055"
    volumes:
      - directus_uploads:/directus/uploads
    environment:
      SECRET: "replace-with-random-secret-string"
      DB_CLIENT: "pg"
      DB_HOST: "postgres"
      DB_PORT: "5432"
      DB_DATABASE: "${POSTGRES_DB}"
      DB_USER: "${POSTGRES_USER}"
      DB_PASSWORD: "${POSTGRES_PASSWORD}"
      ADMIN_EMAIL: "admin@notedalchianti.it"
      ADMIN_PASSWORD: "replace-with-strong-password"
```

Add to `volumes:`:
```yaml
  directus_uploads:
```

- [ ] **Step 3: Start Directus**

```bash
docker compose up -d directus
```

Wait ~30 seconds for first-time initialization.

- [ ] **Step 4: Verify Directus is running**

```bash
curl -s http://localhost:8055/server/health | python3 -m json.tool
```

Expected: `{"status": "ok"}`

- [ ] **Step 5: Get or create Directus API token**

Open `http://localhost:8055` in browser (or via SSH tunnel), login with admin credentials. Go to **Settings → API Access → Static Tokens → Create Token**. Copy the token — needed for Task 5.

- [ ] **Step 6: Create the `essenze` collection in Directus**

```bash
DIRECTUS_TOKEN="<your-token>"

curl -s -X POST http://localhost:8055/collections \
  -H "Authorization: Bearer $DIRECTUS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "collection": "essenze",
    "fields": [
      {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}},
      {"field": "nome", "type": "string", "schema": {"is_nullable": false}},
      {"field": "categoria", "type": "string"},
      {"field": "contenuto_it", "type": "text"},
      {"field": "contenuto_en", "type": "text"},
      {"field": "descrizione", "type": "text"},
      {"field": "tipo", "type": "string"},
      {"field": "immagini", "type": "json"}
    ]
  }'
```

- [ ] **Step 7: Verify collection created**

```bash
curl -s http://localhost:8055/collections/essenze \
  -H "Authorization: Bearer $DIRECTUS_TOKEN" | python3 -m json.tool
```

Expected: JSON describing the `essenze` collection.

---

## Task 4: Configure nginx timeout

**Files:** nginx site config (path varies — typically `/etc/nginx/sites-available/n8n` or `/etc/nginx/conf.d/n8n.conf`)

- [ ] **Step 1: Find the nginx config for n8n**

```bash
grep -r "n8n\|5678" /etc/nginx/ 2>/dev/null
```

Note the file path containing the n8n proxy configuration.

- [ ] **Step 2: Add timeout directives**

Inside the `location` block that proxies to n8n (the one with `proxy_pass`), add:

```nginx
proxy_read_timeout 120s;
proxy_send_timeout 120s;
proxy_connect_timeout 10s;
```

Example final `location` block:
```nginx
location / {
    proxy_pass http://localhost:5678;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 120s;
    proxy_send_timeout 120s;
    proxy_connect_timeout 10s;
}
```

- [ ] **Step 3: Test nginx config**

```bash
nginx -t
```

Expected: `syntax is ok` and `test is successful`.

- [ ] **Step 4: Reload nginx**

```bash
systemctl reload nginx
```

- [ ] **Step 5: Verify with a slow request simulation**

No automated test needed — the timeout will be validated when the first real AI workflow runs.

---

## Task 5: Configure n8n credentials

**Files:** none (n8n UI / REST API)

- [ ] **Step 1: Create OpenRouter credential**

In n8n: **Settings → Credentials → New → HTTP Header Auth**
- Name: `OpenRouter`
- Header: `Authorization`
- Value: `Bearer <your-openrouter-api-key>`

- [ ] **Step 2: Create Postgres credential for sessions**

In n8n: **Settings → Credentials → New → Postgres**
- Name: `Sessions DB`
- Host: `postgres` (Docker service name) or `localhost`
- Port: `5432`
- Database: `<n8n-db-name>`
- User: `<n8n-db-user>`
- Password: `<n8n-db-password>`

Test the connection — must show "Connection successful".

- [ ] **Step 3: Create Qdrant credential**

In n8n: **Settings → Credentials → New → Qdrant**
- Name: `Qdrant Local`
- URL: `http://qdrant:6333` (Docker service name) or `http://localhost:6333`
- API Key: leave empty (no auth on local instance)

- [ ] **Step 4: Create Directus credential**

In n8n: **Settings → Credentials → New → HTTP Header Auth**
- Name: `Directus`
- Header: `Authorization`
- Value: `Bearer <directus-api-token-from-task-3-step-5>`

- [ ] **Step 5: Create Exa.ai credential**

In n8n: **Settings → Credentials → New → HTTP Header Auth**
- Name: `Exa AI`
- Header: `x-api-key`
- Value: `<exa-api-key>` (from original Voiceflow variable `exa_api`)

- [ ] **Step 6: Verify all 5 credentials appear in the credentials list**

In n8n UI: **Settings → Credentials** — confirm: `OpenRouter`, `Sessions DB`, `Qdrant Local`, `Directus`, `Exa AI`.

---

## Phase 0 Complete — Verification Checklist

- [ ] `sessions` table exists in Postgres with JSONB `state` column
- [ ] Qdrant running at `localhost:6333`, collection `essenze` created
- [ ] Directus running at `localhost:8055`, collection `essenze` with all fields
- [ ] nginx timeout set to 120s, config test passes
- [ ] 5 n8n credentials configured: OpenRouter, Sessions DB, Qdrant Local, Directus, Exa AI
