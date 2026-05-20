# 00 — Migration Index

**How to use:** For each n8n migration task, load only the files listed. Avoid loading ROOT.md in full unless you're working on multiple ROOT blocks — load specific sections by block name instead.

---

## Agents

### Task: Migrate Routing Agent
Files: `agents/routing-agent.md`, `variables.md` (rows: `default_language`, `tone_of_voice`, `target_gender`)

### Task: Migrate Target Agent
Files: `agents/target-agent.md`, `variables.md` (row: `target_gender`)

### Task: Migrate Sorting Agent
Files: `agents/sorting-agent.md`, `variables.md` (rows: `perfume_memory`, `target_gender`, `perfume_type`)

### Task: Migrate Memory Extraction Agent
Files: `agents/memory-extraction-agent.md`, `variables.md` (rows: `perfume_memory`, `qna_list`, `enough_info`, `tone_of_voice`)

### Task: Migrate Essence Selection Agent
Files: `agents/essence-selection-agent.md`, `variables.md` (rows: `final_essences`, `parsed_chunks`, `selectedChunks`, `qna_list`)

### Task: Migrate Choice Description Agent
Files: `agents/choice-description-agent.md`, `variables.md` (rows: `final_essences`, `tone_of_voice`)

### Task: Migrate Carousel Pipeline Agents
Files: `agents/carousel-pipeline-agents.md`, `functions/create-carousel.md`, `functions/create-essence-carousel.md`, `variables.md` (rows: `final_essences`, `parsed_chunks`, `essences_per_carousel`)

---

## ROOT Diagram — by section

### Task: Migrate ROOT > Intro + Gender Select
Files: `diagrams/ROOT.md#intro-gender-select`, `agents/routing-agent.md`, `diagrams/Target-Selector.md`, `variables.md` (rows: `target_gender`, `default_language`)

### Task: Migrate ROOT > Sorting Agent + Path Selection
Files: `diagrams/ROOT.md` (blocks: New Block 56, New Block 74, New Block 83, New Block 83 copy, New Block 84, New Block 27), `agents/sorting-agent.md`, `variables.md` (rows: `perfume_memory`, `target_gender`, `perfume_type`)

### Task: Migrate ROOT > Memory Path
Files: `diagrams/ROOT.md` (blocks: Memory Path Intro, Description Listening, Base Essence Validator, Retireve Memory Info, New Block 32, New Block 33), `agents/memory-extraction-agent.md`, `variables.md` (rows: `perfume_memory`, `qna_list`, `enough_info`)

### Task: Migrate ROOT > Essence Path Intro (Inspiration path)
Files: `diagrams/ROOT.md` (blocks: Essence Path Intro, New Block 83 copy, Begin Essence Search), `agents/sorting-agent.md`, `variables.md` (rows: `perfume_memory`, `kb_results`)

### Task: Migrate ROOT > Fragrance Path Intro (Renaissance path)
Files: `diagrams/ROOT.md` (blocks: Fragrance Path Intro, New Block 83 copy copy, New Block 83 copy, New Block 74), `variables.md` (rows: `perfumes_available`, `perfume_memory`)

### Task: Migrate ROOT > KB Search Loop (Get Essences → Show Carousel → Analyze)
Files: `diagrams/ROOT.md` (blocks: Get Essences, Show Essences Carousel, Post-Process Selection, Add Essence to Selection, Analyze Selected Chunks), `diagrams/KB-Search-48.md`, `diagrams/JSON-list-to-carousel.md`, `functions/update-chunk-to-fetch.md`, `functions/add-fetched-chunk.md`, `functions/remove-chosen-essences.md`, `variables.md`

### Task: Migrate ROOT > Essence Follow Up + 5th Essence Prompt
Files: `diagrams/ROOT.md` (blocks: Essence Follow Up, Prompt 5th Essence, Amplify or Go On, Prompt Enhance Essence, New Block 55, New Block 59), `variables.md` (rows: `selectedChunks`, `enough_info`)

### Task: Migrate ROOT > Finish Perfume Creation
Files: `diagrams/ROOT.md` (blocks: Finish Perfume Creation, Perfume Intensity, Additional Notes), `variables.md` (rows: `generalInfo`, `selectedChunks`, `perfume_type`, `target_gender`)

### Task: Migrate ROOT > Naming Ritual + Save Name
Files: `diagrams/ROOT.md` (blocks: Naming Ritual, Show Suggestion Buttons, Save Name Reply, New Block 34, New Block 54, New Block 35, New Block 36), `variables.md` (rows: `perfumeName`)

### Task: Migrate ROOT > Finish Journey + generalInfo export
Files: `diagrams/ROOT.md` (blocks: Finish Journey, New Block 37, New Block 39, New Block 25), `functions/create-general-info.md`, `variables.md` (rows: `generalInfo`, `perfumeName`, `selectedChunks`)

### Task: Migrate ROOT > Essence Select + Remove sub-blocks
Files: `diagrams/ROOT.md` (blocks: Essence Select, Essence Removal, Create Buttons, Retrieve Selection, New Block 3, New Block 4, New Block 5, Keep Going), `diagrams/Select-Essence.md`, `functions/add-essence-to-selection.md`, `functions/remove-essence.md`, `functions/create-essence-buttons.md`, `functions/show-buttons.md`, `variables.md` (rows: `selectedChunks`, `blacklistEssences`)

---

## Sub-Diagrams

### Task: Migrate KB Search (48-node — main loop)
Files: `diagrams/KB-Search-48.md`, `functions/update-chunk-to-fetch.md`, `functions/add-fetched-chunk.md`, `functions/remove-chosen-essences.md`, `functions/manage-blacklisted-essences.md`, `agents/essence-selection-agent.md`, `variables.md` (rows: `kb_results`, `parsed_chunks`, `final_chunks`, `currentEssenceIndex`, `final_essences`, `blacklistEssences`, `qna_list`)

### Task: Migrate KB Search (24-node — legacy routing-agent version)
Files: `diagrams/KB-Search-24.md`, `agents/routing-agent.md`, `agents/memory-extraction-agent.md`, `variables.md` (rows: `kb_results`, `qna_list`, `parsed_chunks`)

### Task: Migrate JSON List to Carousel (36-node)
Files: `diagrams/JSON-list-to-carousel.md`, `agents/carousel-pipeline-agents.md`, `functions/create-carousel.md`, `functions/create-essence-carousel.md`, `functions/process-selected-chunk.md`, `functions/post-process-essences.md`, `functions/add-essence-to-selection.md`, `functions/manage-blacklisted-essences.md`, `variables.md` (rows: `final_essences`, `parsed_chunks`, `selectedChunks`, `blacklistEssences`, `essences_per_carousel`)

### Task: Migrate Select Essence (11-node — button UI)
Files: `diagrams/Select-Essence.md`, `functions/create-essence-buttons.md`, `functions/show-buttons.md`, `functions/add-essence-to-selection.md`, `variables.md` (rows: `selectedChunks`, `final_essences`)

### Task: Migrate Target Selector (12-node)
Files: `diagrams/Target-Selector.md`, `agents/target-agent.md`, `variables.md` (row: `target_gender`)

### Task: Migrate Perfume Type Selector (7-node)
Files: `diagrams/Perfume-Type-Selector.md`, `variables.md` (row: `perfume_type`)

### Task: Migrate Show Language Buttons (9-node)
Files: `diagrams/Show-Language-Buttons.md`, `functions/show-languaged-buttons.md`, `functions/find-italian-choice.md`, `variables.md` (row: `default_language`)

### Task: Migrate Perfect Prompt Generator (10-node)
Files: `diagrams/Perfect-Prompt-Generator.md`, `functions/create-general-info.md`, `variables.md` (rows: `generalInfo`, `selectedChunks`, `perfumeName`, `target_gender`, `perfume_type`, `tone_of_voice`)

---

## Functions (standalone)

### Task: Migrate create-carousel / create-essence-carousel
Files: `functions/create-carousel.md`, `functions/create-essence-carousel.md`, `variables.md` (rows: `final_essences`, `parsed_chunks`, `essences_per_carousel`)

### Task: Migrate create-essence-buttons / show-buttons
Files: `functions/create-essence-buttons.md`, `functions/show-buttons.md`, `variables.md` (rows: `selectedChunks`, `final_essences`)

### Task: Migrate add/remove essence functions
Files: `functions/add-essence-to-selection.md`, `functions/remove-essence.md`, `functions/process-selected-chunk.md`, `functions/post-process-essences.md`, `variables.md` (rows: `selectedChunks`, `parsed_chunks`)

### Task: Migrate KB pagination functions
Files: `functions/update-chunk-to-fetch.md`, `functions/add-fetched-chunk.md`, `functions/remove-chosen-essences.md`, `variables.md` (rows: `currentEssenceIndex`, `final_essences`, `kb_results`, `blacklistEssences`)

### Task: Migrate blacklist management
Files: `functions/manage-blacklisted-essences.md`, `variables.md` (row: `blacklistEssences`)

### Task: Migrate language / button helpers
Files: `functions/show-languaged-buttons.md`, `functions/find-italian-choice.md`, `variables.md` (row: `default_language`)

### Task: Migrate verify-id
Files: `functions/verify-id.md`

### Task: Migrate create-general-info
Files: `functions/create-general-info.md`, `variables.md` (rows: `generalInfo`, `selectedChunks`, `perfumeName`, `target_gender`, `perfume_type`, `qna_list`, `tone_of_voice`)

---

## Cross-cutting references

### Task: Set up all n8n variables (Set nodes)
Files: `variables.md`, `migration-mapping.md`

### Task: Understand Voiceflow → n8n node mapping
Files: `migration-mapping.md`

### Task: Full variable dependency audit
Files: `variables.md`, `agents/routing-agent.md`, `agents/memory-extraction-agent.md`, `agents/essence-selection-agent.md`, `agents/sorting-agent.md`
