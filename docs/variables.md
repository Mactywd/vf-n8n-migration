# Variables

All state variables used in the Alchimista NdC Voiceflow flow.

101 variables total: 82 custom (user-defined) + 19 Voiceflow system variables.

> **Note on "Read by" / "Written by"**: Columns marked `(inferred)` are derived from flow architecture, naming conventions, and project context rather than explicit JSON metadata (the JSON carries no read/write annotations).

---

## Custom Variables

| Variable | Type | Default | Description | Read by | Written by |
|----------|------|---------|-------------|---------|------------|
| `additionalInfo` | any | `"none"` | Extra context beyond primary path info, fed to agents as supplemental data | Essence Selection Agent, KB Search diagram (inferred) | Set nodes in ROOT diagram (inferred) |
| `api_key` | any | `"VF.DM.687f9621…"` | Voiceflow KB API key used in HTTP requests to the knowledge base | KB search nodes (all diagrams) | Initialized at flow start (set-v3 node) |
| `blacklistEssence` | any | null | Singular essence name staged for blacklist addition before calling Manage Blacklisted Essences function | `Manage Blacklisted Essences` function | Carousel / Select Essence diagram (inferred) |
| `blacklistEssences` | any | `[]` | Array of essence names to exclude from future KB searches | KB Search diagram, `Remove Chosen Essences` function | `Manage Blacklisted Essences` function |
| `buttons` | any | null | Button array rendered in the chat UI for choice prompts | `Show Language Buttons` diagram | `Create Essence Buttons` / `Show Buttons` function |
| `bypass_kbsearch_chunks` | any | null | Flag to skip KB search and use pre-loaded chunks directly | KB Search diagram (inferred) | Set nodes in ROOT diagram (inferred) |
| `card_desc` | any | null | Description text for a single carousel card | `JSON list to carousel` diagram | `Create Carousel` / Carousel Agents (inferred) |
| `card_image` | any | null | Image URL for a single carousel card | `JSON list to carousel` diagram | `Create Carousel` / Carousel Agents (inferred) |
| `card_title` | any | null | Title text for a single carousel card | `JSON list to carousel` diagram | `Create Carousel` / Carousel Agents (inferred) |
| `carouselData` | any | null | Fully built carousel JSON structure ready for rendering | Voiceflow carousel node in ROOT | `Create Carousel` / `Create Essence Carousel` function |
| `carouselIDs` | any | null | Array of chunk IDs present in the currently rendered carousel | `JSON list to carousel` diagram, `Verify ID` function | `Create Carousel` / Carousel Agents (inferred) |
| `categoria_followup` | any | null | Follow-up question or prompt related to a selected essence category | Essence Follow Up block in ROOT (inferred) | Essence Selection Agent / set-v3 node (inferred) |
| `categories` | any | null | List of essence categories used for filtering or follow-up queries | KB Search diagram, Essence Selection Agent (inferred) | Set nodes / `Post Process Essences` function (inferred) |
| `chosenCategory` | any | null | The single essence category chosen by the user for targeted KB search | KB Search diagram | Set node after user selection (inferred) |
| `chosenPath` | any | null | The creation path chosen by the user: `memory`, `inspiration`, or `renaissance` | Sorting Agent, ROOT condition nodes | Capture node after Sorting Agent response (inferred) |
| `chosen_fragrance` | any | null | Name of an existing NdC perfume chosen by the user (Renaissance path) | Essence Selection Agent, Inspiration path agents | Capture node in Fragrance Path Intro block (inferred) |
| `conversation_state` | any | null | Snapshot of conversation progress used for recovery or branching logic | ROOT condition nodes (inferred) | Set nodes in ROOT diagram (inferred) |
| `currentEssence` | any | null | The single essence object currently being processed or described | `Choice Description Agent`, `JSON list to carousel` diagram | `Update Chunk to Fetch` / `Add Fetched Chunk` function |
| `currentEssenceIndex` | any | null | Pagination cursor pointing to the next essence to fetch from `final_essences` | `Update Chunk to Fetch` function | `Update Chunk to Fetch` function |
| `current_fragrance_essence` | any | `"0"` | Index of the current fragrance essence being iterated during the Renaissance / Inspiration path essence loop | Essence pipeline loop nodes (inferred) | Set / increment nodes in ROOT diagram (inferred) |
| `default_language` | any | `""` | Active language code: `it` (Italian) or `en` (English) | `Show Language Buttons` diagram, `Show Languaged Buttons` function, all agent prompts | Language Selector / `Show Language Buttons` diagram |
| `documentID` | any | `"687f99a3…"` | Voiceflow KB document ID used in KB search API calls | KB search nodes (all diagrams) | Initialized at flow start (set-v3 node) |
| `enhancedCategory` | any | `"none"` | LLM-enriched or normalized category string used to refine KB queries | KB Search diagram | Essence Selection Agent / set-v3 node (inferred) |
| `enhancedEssence` | any | null | An existing essence from `selectedChunks` chosen for enhancement (5th essence slot) | `Prompt Enhance Essence` block in ROOT | Capture / set node in ROOT (inferred) |
| `enough_info` | any | null | Boolean signal from Memory Extraction Agent indicating enough data has been gathered to proceed to essence selection | ROOT condition node after Memory Extraction Agent | Memory Extraction Agent (output var) |
| `error_message` | any | null | Human-readable error text set when a function or validation step fails | Carousel error-handling agent (inferred) | Carousel Agents / `Create Carousel` function |
| `exa_api` | any | `"a22959a0-…"` | API key for the Exa search service used in the Inspiration path | Inspiration path HTTP Request node | Initialized at flow start (set-v3 node) |
| `exampleCategories` | any | null | Example category strings shown to agents as few-shot prompts | Essence Selection Agent, KB Search diagram | Set node in ROOT (inferred) |
| `examples` | any | null | Few-shot examples injected into agent prompts | Essence Selection Agent (inferred) | Set nodes in ROOT / KB Search diagram (inferred) |
| `examplesusage` | any | null | Usage examples for agent instructions or prompt construction | Agent prompt nodes (inferred) | Set nodes in ROOT (inferred) |
| `essence_description` | any | null | Poetic description text generated for a single essence | `JSON list to carousel` diagram, display nodes | `Choice Description Agent` (output var) |
| `essence_descriptions` | any | `[]` | Array of poetic descriptions accumulated as the carousel pipeline runs | `JSON list to carousel` diagram | `Choice Description Agent` / `Create Carousel` function |
| `essence_query` | any | null | The KB search query string for the current essence lookup | KB search nodes | KB Search diagram / set-v3 node |
| `essenceName` | any | null | Name of a single essence being looked up or described | KB search nodes, `Choice Description Agent` | Set node in ROOT / Carousel pipeline (inferred) |
| `essences` | any | null | Intermediate list of essences returned by Essence Selection Agent before pagination | `Update Chunk to Fetch` function, KB Search diagram | Essence Selection Agent (output var) |
| `essences_per_carousel` | any | `"4"` | Number of essences to show per carousel page (pagination size) | `Create Carousel` / `Create Essence Carousel` function, `Update Chunk to Fetch` function | Initialized at flow start (set-v3 node); default 4 |
| `failedIterations` | any | `"0"` | Counter for KB search iterations that returned no valid results | KB Search condition nodes | Set / increment nodes in KB Search diagram (inferred) |
| `fast_thought` | any | null | Short internal reasoning note from an AI agent (chain-of-thought, fast pass) | ROOT condition nodes (inferred) | Routing Agent / Sorting Agent (output var) |
| `final_chunks` | any | null | Final processed array of KB chunks ready for carousel rendering | `Create Carousel` / `Create Essence Carousel` function | `Add Fetched Chunk` / `Process Selected Chunk` function |
| `final_essence` | any | null | The single essence selected by the user from the current carousel | `Add Essence to Selection` function | Capture node in `Select Essence` diagram |
| `final_essences` | any | null | Serialized (JSON string) list of all essence KB chunks to page through | `Update Chunk to Fetch` function, `Add Fetched Chunk` function | Essence Selection Agent / KB search results (set-v3 node) |
| `final_label` | any | null | Localized button label resolved after language lookup | ROOT display nodes | `Find Italian Choice` / `Show Languaged Buttons` function |
| `fragrance_description` | any | null | Short descriptive text about the user-referenced fragrance (Inspiration path) | Inspiration path agents | Exa API response processing / set-v3 node (inferred) |
| `fragrance_notes` | any | null | Olfactory notes extracted for a reference fragrance (Inspiration path) | Essence Selection Agent | Exa API response processing / set-v3 node (inferred) |
| `generalInfo` | any | null | Final structured summary object containing all collected user choices and preferences | `Perfect Prompt Generator` diagram, Finish Perfume Creation | `Create generalInfo` function |
| `isSelectionValid` | any | null | Boolean flag indicating whether the user's carousel selection passed validation | `JSON list to carousel` condition nodes | `Verify ID` function |
| `italian_labels` | any | null | Array of Italian button label strings for bilingual button rendering | `Show Languaged Buttons` / `Find Italian Choice` function | Set node in `Show Language Buttons` diagram (inferred) |
| `english_labels` | any | null | Array of English button label strings for bilingual button rendering | `Show Languaged Buttons` / `Find Italian Choice` function | Set node in `Show Language Buttons` diagram (inferred) |
| `kb_results` | any | null | Raw KB search response from the Voiceflow knowledge base API | KB Search diagram (parsing step) | KB search nodes (`kb-search` type) |
| `long_thought` | any | null | Extended internal reasoning note from an AI agent (deep chain-of-thought) | ROOT condition nodes (inferred) | Routing Agent / Sorting Agent (output var) |
| `memory_description` | any | null | Structured or condensed description of the user's sensory memory, derived from the Memory Extraction Agent dialogue | Essence Selection Agent, KB query generation | Memory Extraction Agent (output var) |
| `mustChoose` | any | null | Flag forcing the user to make a selection from the current carousel (blocks "skip" path) | `JSON list to carousel` condition nodes | Set node in ROOT / KB Search diagram (inferred) |
| `nameSuggestions` | any | null | Array of fragrance name suggestions generated by the AI before the Naming Ritual | Naming Ritual block (display) | `Perfect Prompt Generator` agent / set-v3 node (inferred) |
| `parsed_chunks` | any | null | Intermediate parsed array from raw `kb_results` string before final processing | `Final Chunks` step in KB pipeline | KB Search diagram / `Process Selected Chunk` function |
| `pathInfoField` | any | null | Field name of path-specific data to store (used with `pathInfoValue` for generic path logging) | ROOT condition / set nodes (inferred) | Sorting Agent / set-v3 node (inferred) |
| `pathInfoValue` | any | null | Value corresponding to `pathInfoField` (path-specific data payload) | ROOT condition / set nodes (inferred) | Sorting Agent / set-v3 node (inferred) |
| `perfumeName` | any | null | The name chosen by the user for their custom fragrance during the Naming Ritual | `Save Name Reply` block, `Create generalInfo` function | Capture node in Naming Ritual block |
| `perfume_description` | any | null | Full generated description of the co-created perfume | Finish Perfume Creation block | `Perfect Prompt Generator` diagram (output var) |
| `perfume_intensity` | any | null | Intensity level of the custom perfume (e.g. light, moderate, intense) | `Perfect Prompt Generator` diagram, `Create generalInfo` function | Capture node or agent output (inferred) |
| `perfume_memory` | any | null | Raw user text describing the memory they want to recreate | Memory Extraction Agent, Essence Selection Agent | Capture node in Memory Path Intro block |
| `perfume_type` | any | null | Usage context: `home` (home fragrance) or `personal` (personal perfume) | Sorting Agent, Essence Selection Agent, `Create generalInfo` function | `Perfume Type Selector` diagram |
| `perfumes_available` | any | `[16 NdC names]` | Static catalog of the 16 NdC fragrances available (used in Renaissance path) | Sorting Agent, Fragrance Path Intro block | Initialized at flow start (static set-v3 node) |
| `pre_kb_thought` | any | null | Internal reasoning note generated just before a KB search to guide query construction | KB Search diagram | KB Search agent (output var) |
| `preGeneralInfo` | any | null | Partial `generalInfo` object assembled before the final creation step; used as a draft | `Create generalInfo` function (inferred) | Set nodes prior to Finish Perfume Creation (inferred) |
| `query_feedback` | any | null | Feedback signal from the agent about the quality or relevance of the last KB query result (note: two entries with this name exist in the JSON — likely a duplicate) | KB Search condition nodes | KB Search Agent (output var) |
| `qna_list` | any | `""` | Accumulated string of Q&A pairs from the Memory Extraction dialogue, used to refine KB queries | KB Search diagram (query generation agent) | Capture nodes in Memory Path; appended after each user reply |
| `selectionID` | any | null | UUID of the carousel item selected by the user | `Verify ID` function, `JSON list to carousel` diagram | Capture node in `Select Essence` / `JSON list to carousel` diagram |
| `selectionName` | any | null | Display name of the carousel item selected by the user | `Add Essence to Selection` function, ROOT blocks | Capture node in `Select Essence` / `JSON list to carousel` diagram |
| `selectedChunk` | any | null | A single KB chunk object being processed in the current loop iteration | `Process Selected Chunk` function, `Choice Description Agent` | `Add Fetched Chunk` / `Update Chunk to Fetch` function |
| `selectedChunks` | any | `[]` | Array of all essence KB chunks chosen by the user so far (max 5) | Essence Selection Agent, `Create generalInfo` function, carousel functions | `Add Essence to Selection` function |
| `selectedChunksLength` | any | null | Numeric length of `selectedChunks`, used for branching logic (e.g. is max reached?) | ROOT condition nodes | Set node after each `Add Essence to Selection` call (inferred) |
| `selectedEssence` | any | null | The currently highlighted or selected essence object in the UI flow | `Choice Description Agent`, `Add Essence to Selection` function | Capture node in `Select Essence` diagram |
| `shouldSaveName` | any | null | Boolean flag indicating whether the user confirmed they want to save the suggested perfume name | `Save Name Reply` condition node | Capture node in Naming Ritual (inferred) |
| `target_gender` | any | `"Uomo"` | Intended perfume recipient gender: `Uomo` / `Donna` / `Unisex` | Sorting Agent, Memory Extraction Agent, Essence Selection Agent, `Create generalInfo` function | `Target Selector` diagram |
| `temp_variable` | any | null | General-purpose scratch variable used for intermediate computation in Code/Function nodes | Various Code nodes (inferred) | Various Code / Function nodes (inferred) |
| `tone_of_voice` | any | *(long poetic style instruction)* | Mystical/poetic style instruction injected into all agent system prompts | All agent `response-prompt` nodes | Initialized at flow start (set-v3 node; static value) |
| `usecaseinfo` | any | null | Additional use-case context passed to agents for better situational reasoning | Agent prompt nodes (inferred) | Set nodes in ROOT diagram (inferred) |
| `user_essence` | any | null | A raw essence string typed or expressed by the user, before KB lookup | KB search nodes, Essence Selection Agent (inferred) | Capture node in Essence Path Intro (inferred) |
| `user_query` | any | null | The user's free-text query captured before a KB search step | KB Search diagram | Capture node / set-v3 node in ROOT (inferred) |
| `userCanWrite` | any | null | Flag controlling whether the chat input is enabled for text entry | ROOT / webchat UI control (inferred) | Set nodes in ROOT diagram (inferred) |
| `validation_output` | any | null | Output from a validation step (e.g. JSON validity check in carousel pipeline) | Carousel condition nodes | `Verify ID` / Carousel Agents |

---

## Voiceflow System Variables

These are read-only variables automatically provided by the Voiceflow runtime.

| Variable | Type | Description |
|----------|------|-------------|
| `intent_confidence` | number | Confidence score (0–100) for the last matched intent |
| `last_event` | any | Last UI event object triggered by the user client |
| `last_response` | text | The agent's last text response |
| `last_utterance` | text | The user's last text input |
| `locale` | text | User locale string (e.g. `en-US`, `it-IT`) |
| `platform` | text | Platform name (e.g. `"voiceflow"`) |
| `sessions` | number | Number of times the user has opened the app |
| `timestamp` | text | UNIX timestamp (seconds since epoch) |
| `user_id` | text | Unique user identifier |
| `vf_date` | date | Current date (`Jan 1, 2025`) |
| `vf_day` | number | Current day of month |
| `vf_memory` | text | Last 10 exchanges as formatted string |
| `vf_month` | text | Current month name (`January`) |
| `vf_now` | date | Current date + time (`Jan 1, 2025, 16:37`) |
| `vf_time` | text | Current time (`16:37`) |
| `vf_transcript_id` | text | Transcript ID for the current conversation |
| `vf_user_timezone` | text | User's timezone string (`America/Toronto`) |
| `vf_weekday` | text | Current weekday name (`Monday`) |
| `vf_year` | number | Current year |

---

## Variables with Uncertain Classification

The following variables had no explicit description in the JSON and their exact role required inference from naming conventions and flow context. All are marked `(inferred)` in the main table.

| Variable | Uncertainty reason |
|----------|-------------------|
| `bypass_kbsearch_chunks` | Created 2025-09-11; name suggests a debug/testing bypass flag but no usage found in diagram metadata |
| `conversation_state` | Generic name; may be unused or used only in a deprecated diagram branch |
| `examplesusage` | Ambiguous name; likely holds usage instructions for agent few-shot examples |
| `pathInfoField` / `pathInfoValue` | Generic key/value pair pattern; exact schema of what field/value pairs are stored is unclear |
| `preGeneralInfo` | Partial draft object; unclear if it persists between sub-flows or is transient |
| `query_feedback` | Appears **twice** in the variables array with different IDs but identical name — likely a duplicate created in error |
| `temp_variable` | Explicitly a scratch variable; no stable semantics |
| `userCanWrite` | Created 2026-01-04; controls UI input state, possibly for loading/streaming UX gating |
