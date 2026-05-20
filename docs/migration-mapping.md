# Voiceflow → n8n Node Type Migration Mapping

Generated from: `alchimista.json` (Voiceflow v13.09 export)
Diagrams parsed: ROOT, KB Search (48), KB Search (24), JSON list to carousel with random image,
Select Essence, Target Selector, Perfume Type Selector, Show Lamguage Buttons, Perfect Prompt Generator

---

## Node Type Reference

| Voiceflow type | Total count | Count in ROOT | n8n equivalent | Migration notes |
|----------------|-------------|---------------|----------------|-----------------|
| `block` | 161 | 101 | — (Sticky Note) | Logical grouping only; no executable n8n node needed. Use sticky notes or sub-workflow boundaries for visual organization. |
| `set-v3` | 81 | 55 | Set node | Maps variables 1:1. Multiple assignments in one `set-v3` become one n8n Set node with multiple fields. Supports expressions and literal values. |
| `function` | 39 | 26 | Code node (JavaScript) | Each function reads from `args.inputVars` and returns `{ outputVars: {...} }`. In n8n Code nodes, use `$input` items and return objects. Full function source documented in `functions/` directory. |
| `response-prompt` | 31 | 27 | AI Agent node | Invokes an LLM with a system prompt. System prompts and model config documented per-agent in `agents/` directory. Language adapts dynamically via `default_language` variable. |
| `actions` | 27 | 21 | HTTP Request node | Wraps one or more outbound actions (API calls, webhook sends, etc.). Steps are resolved via node IDs; inspect each to determine HTTP method and endpoint. |
| `condition-v3` | 23 | 16 | If node / Switch node | Single boolean condition → n8n If node. Three or more branches → Switch node. Conditions reference Voiceflow variables that map directly to n8n workflow variables. |
| `component` | 19 | 17 | Execute Workflow node | Calls a reusable sub-flow (another Voiceflow diagram). Each `component` maps to an n8n "Execute Workflow" node pointing at the corresponding sub-workflow. |
| `goToNode` | 19 | 15 | Execute Workflow node / Jump | Jumps to another node or diagram. Within the same workflow, wire the output port directly. Cross-diagram jumps become Execute Workflow nodes. |
| `capture-v3` | 14 | 9 | Wait for Webhook / Chat Trigger | Pauses execution and waits for user input, storing the reply in a variable (always `last_utterance` or a named variable ID). In n8n, implement as a webhook wait step or use the Chat Trigger for the entry point. |
| `message` | 13 | 4 | Send Message node | Sends a static or templated text message to the user. In n8n Chat integrations, use a Respond to Webhook node or a dedicated messaging channel node. |
| `markup_text` | 10 | 8 | — (Sticky Note) | Canvas annotation / label only. Contains display text (e.g. "KB Search", "debugging purposes"). No runtime behavior; convert to n8n sticky notes for documentation. |
| `kb-search` | 9 | 6 | HTTP Request node (KB API) | Queries the Voiceflow Knowledge Base. Document ID: `687f99a3854389cf5efea956`. Query pattern: `"Nome: {essenceName}"` or `"Categoria: {category}"`. Returns up to 4–10 chunks. In n8n, replace with an HTTP Request to the Voiceflow KB endpoint or a vector-store lookup node. |
| `start` | 7 | 1 | Trigger node (entry point) | Diagram entry point. The ROOT `start` node becomes the primary Chat Trigger. Sub-diagram `start` nodes become the entry trigger of their respective sub-workflows (Execute Workflow callee). |
| `exit` | 6 | 5 | End node | Terminates the conversation or sub-flow. Map to n8n's built-in End node or simply leave the output port unconnected at the final step. |
| `code` | 6 | 2 | Code node (JavaScript) | Similar to `function` but typically shorter inline scripts. Same conversion pattern: read inputs, compute, return output object. |
| `trigger` | 2 | 0 | Trigger node | Internal event trigger (used in sub-diagrams like Perfect Prompt Generator). Maps to an n8n Trigger node or a webhook entry for that sub-workflow. |
| `agent` | 2 | 0 | AI Agent node | Direct agent invocation node (distinct from `response-prompt`). Found in the older KB Search (24) diagram. Maps to an AI Agent node with the referenced `agentID` system prompt. |
| `choice-v2` | 1 | 0 | n8n Form / Button node | Presents labeled buttons to the user (e.g. "Per Casa" / "Per Me"). In n8n Chat, send a message with inline buttons or use a Form Trigger; capture the selection with a Switch node on the response. |
| `api-v2` | 1 | 1 | HTTP Request node | Direct HTTP API call with configurable method, URL, headers, and body. Maps cleanly to n8n's HTTP Request node. |

**Total distinct node types: 19**
**Total nodes across all diagrams: 490**

---

## Migration Patterns

### `response-prompt` → AI Agent node

Each `response-prompt` node references a Voiceflow agent definition (by `agentID`). The agent carries a system prompt, model selection, and temperature. In n8n:

1. Create an **AI Agent** node (or **Basic LLM Chain** for single-turn responses).
2. Copy the system prompt from the Voiceflow agent record.
3. Pass the current conversation context (e.g. `qna_list`, `tone_of_voice`, `default_language`) as dynamic input expressions.
4. The agent's reply replaces what Voiceflow would stream to the user; wire it into a **Respond to Webhook** or **Send Message** node.

All 14 agents' prompts are documented in `agents/` (to be generated).

---

### `function` / `code` → Code node (JavaScript)

Voiceflow functions use the signature:

```js
export default async function main(args) {
  const { inputVars } = args;
  // ... compute ...
  return { outputVars: { varName: value } };
}
```

In n8n Code nodes (JavaScript mode):

```js
const varName = $('Previous Node').first().json.varName;
// ... compute ...
return [{ json: { varName: result } }];
```

Key differences:
- Replace `args.inputVars.X` with n8n expressions (`{{ $json.X }}` or `$('Node').first().json.X`).
- `outputVars` becomes the returned JSON object.
- Async/await is supported in n8n Code nodes.

All 18 function bodies are documented in `functions/` (to be generated).

---

### `kb-search` → HTTP Request node (Voiceflow KB API)

Voiceflow KB search nodes hit the internal KB endpoint with a natural-language or structured query.

Equivalent n8n HTTP Request configuration:

- **Method**: POST
- **URL**: `https://general-runtime.voiceflow.com/knowledge-base/query` (or replacement vector store endpoint)
- **Headers**: `Authorization: {{ $vars.api_key }}`
- **Body**:
  ```json
  {
    "chunkLimit": 4,
    "synthesis": false,
    "settings": { "model": "claude-3-haiku", "temperature": 0 },
    "query": "Nome: {{ $json.essenceName }}"
  }
  ```
- **Result**: Parse `chunks[]` from the response; store in `kb_results` / `parsed_chunks`.

For a full n8n-native replacement, swap the HTTP Request for a **Pinecone**, **Supabase Vector Store**, or **Qdrant** node loaded with the same essence knowledge base.

---

### `capture-v3` → Wait for Webhook / Chat Trigger

`capture-v3` halts the flow and stores the next user utterance in a variable. Two n8n patterns:

1. **Stateless webhook per turn** (recommended): Each user message hits the n8n Chat Trigger. The workflow reads `last_utterance` from the incoming payload, processes it, sends a reply, and finishes. State is persisted externally (e.g. a Supabase session row) and reloaded on the next turn.
2. **Webhook wait step**: Use n8n's **Wait** node configured to resume on an incoming webhook. Suitable for long-running workflows that need to hold state in memory across turns.

All 9 ROOT `capture-v3` nodes capture into `last_utterance` (or a named variable); the variable name is preserved in the n8n Set node that follows the wait.

---

### `condition-v3` → If / Switch node

- **Two-branch conditions** (true/false): n8n **If** node.
- **Three or more branches** (e.g. path routing based on `target_gender`, `perfume_type`, or agent output): n8n **Switch** node with one rule per output port.
- Condition operands reference Voiceflow variables that map directly to n8n workflow data fields.

---

### `component` / `goToNode` → Execute Workflow node

Each Voiceflow diagram is a separate n8n workflow. `component` and cross-diagram `goToNode` nodes become **Execute Workflow** nodes that call the target workflow by ID, passing the current session variables as input data and receiving updated variables on completion.

Intra-diagram `goToNode` jumps (within the same workflow) should be resolved by direct port wiring rather than Execute Workflow calls to avoid unnecessary overhead.

---

### `block` / `markup_text` → Sticky Notes

Neither type has runtime behavior. Use n8n **Sticky Note** nodes to replicate the organizational groupings visible on the Voiceflow canvas. Label each sticky note with the original block name (e.g. "Intro + Gender Select", "Get Essences", "Naming Ritual").

---

## Per-Diagram Summary

| Diagram | Nodes | Primary n8n workflow role |
|---------|-------|--------------------------|
| ROOT | 314 | Main conversation engine (primary workflow) |
| KB Search (48 nodes) | 48 | Sub-workflow: iterative KB query + Q&A loop |
| JSON list to carousel with random image | 36 | Sub-workflow: carousel rendering pipeline |
| KB Search (24 nodes) | 24 | Sub-workflow: older/simpler routing-agent KB lookup |
| Perfect Prompt Generator | 10 | Sub-workflow: final fragrance prompt assembly |
| Select Essence | 11 | Sub-workflow: button-based essence selector UI |
| Target Selector | 12 | Sub-workflow: Masc/Fem/Universal picker |
| Perfume Type Selector | 7 | Sub-workflow: home-use vs. personal-gift choice |
| Show Lamguage Buttons | 9 | Sub-workflow: Italian/English language selector |
| Template Diagram | 0 | Empty scaffold; no migration needed |

---

## Variable Mapping Reference

Key Voiceflow state variables and their n8n equivalents (stored as workflow execution data or in an external session store):

| Voiceflow variable | Type | n8n storage pattern |
|--------------------|------|---------------------|
| `last_utterance` | string | `$json.last_utterance` from Chat Trigger payload |
| `target_gender` | string | Set node → session store field |
| `perfume_type` | string | Set node → session store field |
| `selectedChunks` | array | Set node → session store JSON array |
| `blacklistEssences` | array | Set node → session store JSON array |
| `essences_per_carousel` | number | Set node (default: 4) |
| `currentEssenceIndex` | number | Set node, incremented by Code node |
| `final_essences` | string | Set node (serialized JSON string) |
| `qna_list` | string | Set node → accumulated across turns |
| `generalInfo` | object | Set node → final structured summary |
| `perfumeName` | string | Set node (user-chosen name) |
| `default_language` | string | Set node (`it` or `en`) |
| `tone_of_voice` | string | Set node → passed to all AI Agent system prompts |
| `api_key` | string | n8n Credential (HTTP Header Auth) — do not store in workflow data |
| `perfumes_available` | array | Static Set node or hardcoded in Code node (16 NdC fragrances) |
