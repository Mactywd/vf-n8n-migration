# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Alchimista NdC** is a Voiceflow webchat application for **Note del Chianti** (NdC), an artisan perfumery brand. The app guides users through a conversational journey — collecting memories, preferences, and sensory details — to co-create a personalized fragrance.

The entire project lives in `alchimista.json`, a full Voiceflow v13.09 export (~1.5 MB, ~37,000 lines).

## How to Parse the Source File

```bash
# Inspect top-level structure
cat alchimista.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(list(d.keys()))"

# Count nodes per diagram
cat alchimista.json | python3 -c "
import json,sys; d=json.load(sys.stdin)
for k,v in d['diagrams'].items(): print(v['name'], len(v.get('nodes',{})))
"

# Read all variables
cat alchimista.json | python3 -c "
import json,sys; d=json.load(sys.stdin)
for v in d['variables']: print(v['name'], '=', str(v.get('defaultValue',''))[:60])
"
```

Key top-level keys: `diagrams`, `flows`, `variables`, `agents`, `functions`, `workflows`, `responses`, `intents`, `personas`.

## Conversation Architecture

### The Three Creation Paths

After the user lands in the ROOT diagram, every conversation follows one of three journeys chosen by the **Sorting Agent**:

| Path | Trigger | Description |
|------|---------|-------------|
| **Memory** | User wants to recreate a memory | AI extracts sensory/emotional details, translates them into essence choices |
| **Inspiration** | User references an existing perfume | AI finds NdC essences that echo the referenced fragrance |
| **Renaissance** | User starts from an NdC perfume | User customizes an existing NdC creation |

### Diagram Map

| Diagram | Nodes | Role |
|---------|-------|------|
| `ROOT` | 314 | Main conversation engine — the entire journey graph |
| `KB Search` (48 nodes) | 48 | Iterative Q&A loop: generates queries, searches KB, presents chunks |
| `KB Search` (24 nodes) | 24 | Older/simpler routing-agent version |
| `Select Essence` | 11 | Button-based essence selection UI |
| `JSON list to carousel` | 36 | Renders KB chunks as image carousel, handles selection |
| `Target Selector` | 12 | Agent-driven masculine/feminine/universal selection |
| `Perfume Type Selector` | 7 | Home use vs. personal gift choice |
| `Show Language Buttons` | 9 | Language selector (Italian/English fallback) |
| `Perfect Prompt Generator` | 10 | Generates the final fragrance prompt from collected data |

### ROOT Diagram — Key Named Blocks (in order)

`Intro + Gender Select` → `Memory Path Intro` / `Essence Path Intro` / `Fragrance Path Intro` → `Get Essences` → `Base Essence Validator` → `Description Listening` → `Analyze Selected Chunks` → `Essence Follow Up` → `Prompt 5th Essence` / `Prompt Enhance Essence` → `Naming Ritual` → `Show Suggestion Buttons` → `Save Name Reply` → `Finish Perfume Creation`

## AI Agents (14 total)

| Agent | Purpose |
|-------|---------|
| **Routing Agent** | Opening greeter & tone setter. Speaks as *L'Alchimista del Chianti*. Determines path. |
| **Target Agent** | Single-turn: asks for whom the perfume is made (Masculine / Feminine / Universal) |
| **Sorting Agent** | Reveals Memory / Inspiration / Renaissance paths, routes user |
| **Memory Extraction Agent** (x2) | Asks poetic questions to surface sensory/emotional memory details. Never names essences. |
| **Essence Selection Agent** | Analyzes KB chunks + user description, selects 3–4 matching essences |
| **Choice Description Agent** | Writes poetic description for each KB chunk shown to user |
| **Carousel Agents** (4) | Pipeline: validate JSON → select random images → build carousel data structure → error handling |

All agents speak with a mystical, poetic voice ("*L'Alchimista del Chianti*"). Language adapts to the user's language dynamically.

## JavaScript Functions (18 total)

These are Voiceflow custom code steps (TypeScript-ish, `export default async function main(args)`). Each reads/writes Voiceflow variables via `args.inputVars` and returns `{ outputVars: {...} }`.

| Function | What it does |
|----------|-------------|
| `Create Carousel` / `Create Essence Carousel` | Builds carousel JSON from KB chunks with image URLs |
| `Create Essence Buttons` / `Show Buttons` | Formats essence list as clickable button array |
| `Add Essence to Selection` | Appends a chunk to `selectedChunks[]` |
| `Remove Essence` | Removes a chunk from `selectedChunks[]` |
| `Process Selected Chunk` | Parses raw KB chunk into structured essence object |
| `Post Process Essences` | Normalizes whitespace/apostrophes in essence name strings |
| `Remove Chosen Essences` | Filters already-selected essences out of new KB results |
| `Manage Blacklisted Essences` | Adds/removes from `blacklistEssences[]` |
| `Update Chunk to Fetch` | Advances `currentEssenceIndex` for paginated KB fetching |
| `Add Fetched Chunk` | Merges a newly fetched chunk into the working list |
| `Verify ID` | UUID regex validation |
| `Create generalInfo` | Builds a structured summary object from all collected variables |
| `Show Languaged Buttons` | Picks Italian or English button labels based on `default_language` |
| `Find Italian Choice` | Maps an Italian label back to its English equivalent |

## Key State Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `target_gender` | string | `Uomo` / `Donna` / `Unisex` |
| `perfume_type` | string | `home` / `personal` |
| `perfume_memory` | string | Raw user memory description |
| `selectedChunks` | array | Accumulated essence selections (max 5) |
| `blacklistEssences` | array | Essences to exclude from future KB searches |
| `essences_per_carousel` | number | Pagination size (default: 4) |
| `currentEssenceIndex` | number | Current pagination cursor for KB results |
| `final_essences` | string | Serialized list of all KB chunks to show |
| `kb_results` / `parsed_chunks` / `final_chunks` | string/array | KB search pipeline state |
| `qna_list` | string | Accumulated Q&A pairs used to refine KB queries |
| `generalInfo` | object | Final structured summary of all user choices |
| `perfumeName` | string | User's chosen perfume name |
| `default_language` | string | `it` or `en` (set by language selector) |
| `tone_of_voice` | string | Mystical/poetic style instruction passed to agents |
| `perfumes_available` | array | 16 NdC fragrances (catalog, static) |
| `enough_info` | boolean | Signal from Memory Extraction Agent to move to essence selection |

## NdC Perfume Catalog (16 fragrances)

Meriggio, Respiro d'Amore, Sinfonia Mediterranea, Eden, Alba, Dolce Carezza, 1716, Malvasia, Sangiovese, Sogno Toscano, Dolce Adua, Ricordo Segreto, Toscano Intenso, Sottobosco, Tramonto, Anima Libera

## Knowledge Base (Voiceflow Native)

- Document ID: `687f99a3854389cf5efea956`
- API key stored in variable `api_key`
- Queried by: essence name, category string, or free-text user query
- Returns up to 4–10 chunks per search, paginated via `currentEssenceIndex`
- KB search nodes query pattern: `"Nome: {essenceName}"` or `"Categoria: {category}"`

## Voiceflow Node Type Reference

| Voiceflow type | Count in ROOT | Description |
|----------------|--------------|-------------|
| `block` | 101 | Logical grouping / canvas boundary |
| `set-v3` | 55 | Variable assignment |
| `response-prompt` | 27 | AI text generation (LLM call) |
| `function` | 26 | Custom JS function call |
| `actions` | 21 | Internal wrapper container |
| `condition-v3` | 16 | Conditional branching |
| `goToNode` | 15 | Jump to another node or diagram |
| `component` | 17 | Sub-flow call (another diagram) |
| `capture-v3` | 9 | Wait for user input |
| `kb-search` | 6 | Knowledge base search |
| `exit` | 5 | End of flow |
| `message` | 4 | Static text message to user |
| `api-v2` | 1 | HTTP API call |
| `code` | 2 | Inline JS code |
