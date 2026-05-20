-- =============================================================================
-- Alchimista NdC — Session Persistence Schema
-- Supabase / PostgreSQL
-- =============================================================================
-- Naming convention: alchimista_sessions
--
-- Strategy:
--   • Dedicated columns  → variables that survive across turns and drive
--                          branching logic in multiple workflows
--   • JSONB `state`      → pipeline intermediates, carousel scaffolding,
--                          and variables whose schema may change
--   • Excluded entirely  → Voiceflow system vars (replaced by n8n native
--                          equivalents), read-only constants (api_key,
--                          documentID, perfumes_available, tone_of_voice,
--                          essences_per_carousel), pure scratch vars
--                          (temp_variable, query_feedback duplicate)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extension (safe to run even if already enabled)
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Main session table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alchimista_sessions (

    -- -----------------------------------------------------------------------
    -- Identity & timestamps
    -- -----------------------------------------------------------------------
    session_id          TEXT        PRIMARY KEY,           -- UUID or chat-widget session ID from the frontend
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- -----------------------------------------------------------------------
    -- Path & routing  (cross-turn, drive top-level branching)
    -- -----------------------------------------------------------------------
    chosen_path         TEXT        CHECK (chosen_path IN ('memory','inspiration','renaissance')),
    -- 'memory' | 'inspiration' | 'renaissance'

    conversation_state  TEXT,
    -- Snapshot label of current progress (e.g. 'intro', 'essence_selection',
    -- 'naming_ritual', 'done'); used by the main orchestrator to resume.

    -- -----------------------------------------------------------------------
    -- User profile  (set once early, read by many agents)
    -- -----------------------------------------------------------------------
    target_gender       TEXT        CHECK (target_gender IN ('Uomo','Donna','Unisex')),
    perfume_type        TEXT        CHECK (perfume_type IN ('home','personal')),
    default_language    TEXT        CHECK (default_language IN ('it','en')),

    -- -----------------------------------------------------------------------
    -- Path-specific primary inputs
    -- -----------------------------------------------------------------------
    perfume_memory      TEXT,
    -- Raw user text (Memory path)

    chosen_fragrance    TEXT,
    -- NdC perfume name chosen by the user (Renaissance path)

    fragrance_description TEXT,
    -- Short description of the reference fragrance (Inspiration path)

    fragrance_notes     TEXT,
    -- Olfactory notes extracted for the reference fragrance (Inspiration path)

    user_essence        TEXT,
    -- Raw essence string typed by the user (Essence path intro)

    -- -----------------------------------------------------------------------
    -- Memory-extraction dialogue
    -- -----------------------------------------------------------------------
    qna_list            TEXT        NOT NULL DEFAULT '',
    -- Accumulated Q&A pairs from Memory Extraction Agent; append-only.
    -- Stored as plain text (same format as Voiceflow variable).

    memory_description  TEXT,
    -- Condensed sensory description derived from qna_list by the Memory Agent.

    enough_info         BOOLEAN     NOT NULL DEFAULT FALSE,
    -- TRUE when Memory Extraction Agent has gathered sufficient detail.

    -- -----------------------------------------------------------------------
    -- Essence selection (accumulated across multiple carousel turns)
    -- -----------------------------------------------------------------------
    selected_chunks     JSONB       NOT NULL DEFAULT '[]'::JSONB,
    -- Array of selected essence KB chunk objects (max 5).
    -- Schema per element: { id, name, description, category, image_url, ... }

    blacklist_essences  JSONB       NOT NULL DEFAULT '[]'::JSONB,
    -- Array of essence names excluded from future KB searches.

    -- -----------------------------------------------------------------------
    -- Naming ritual
    -- -----------------------------------------------------------------------
    perfume_name        TEXT,
    -- User-chosen perfume name.

    name_suggestions    JSONB,
    -- Array of AI-generated name suggestions shown to the user.

    should_save_name    BOOLEAN,
    -- TRUE if user confirmed they want to keep the suggested name.

    -- -----------------------------------------------------------------------
    -- Final output
    -- -----------------------------------------------------------------------
    perfume_description TEXT,
    -- Full generated description of the co-created perfume.

    perfume_intensity   TEXT,
    -- Intensity level (e.g. 'leggero', 'moderato', 'intenso').

    general_info        JSONB,
    -- Final structured summary built by Create generalInfo function.

    -- -----------------------------------------------------------------------
    -- Pipeline / carousel state  (frequently changing, complex shape)
    -- Stored inside the JSONB `state` column below.
    -- -----------------------------------------------------------------------

    -- -----------------------------------------------------------------------
    -- JSONB catch-all for pipeline intermediates & less-critical vars
    -- -----------------------------------------------------------------------
    state               JSONB       NOT NULL DEFAULT '{}'::JSONB
    -- Holds all remaining variables not worth dedicated columns:
    --
    --   kb_results              TEXT    — raw KB API response
    --   parsed_chunks           JSONB   — intermediate parsed array
    --   final_chunks            JSONB   — processed chunks ready for carousel
    --   final_essences          TEXT    — serialised JSON list (pagination source)
    --   current_essence_index   INTEGER — pagination cursor
    --   current_essence         JSONB   — single essence being processed
    --   essences                JSONB   — raw list from Essence Selection Agent
    --   carousel_data           JSONB   — fully built carousel JSON
    --   carousel_ids            JSONB   — chunk IDs in current carousel
    --   essence_descriptions    JSONB   — accumulated poetic descriptions
    --   additional_info         TEXT    — supplemental context for agents
    --   enhanced_category       TEXT    — LLM-normalised category string
    --   categories              JSONB   — list of essence categories
    --   chosen_category         TEXT    — user-selected category for KB query
    --   enhance_essence         JSONB   — essence chosen for enhancement slot
    --   bypass_kbsearch_chunks  BOOLEAN — debug flag: skip KB search
    --   failed_iterations       INTEGER — KB search failure counter
    --   pre_kb_thought          TEXT    — agent reasoning before KB query
    --   fast_thought            TEXT    — agent fast chain-of-thought
    --   long_thought            TEXT    — agent deep chain-of-thought
    --   additional_info         TEXT
    --   path_info_field         TEXT    — generic key for path logging
    --   path_info_value         TEXT    — generic value for path logging
    --   pre_general_info        JSONB   — partial draft of general_info
    --   user_can_write          BOOLEAN — UI input gate flag
    --   must_choose             BOOLEAN — forces carousel selection
    --   is_selection_valid      BOOLEAN — carousel selection validation result
    --   selection_id            TEXT    — UUID of selected carousel item
    --   selection_name          TEXT    — display name of selected carousel item
    --   final_essence           JSONB   — essence selected from carousel
    --   current_fragrance_essence INTEGER — loop index for Renaissance/Inspiration
    --   usecase_info            TEXT    — extra use-case context for agents
    --   example_categories      TEXT    — few-shot examples for category selection
    --   examples                TEXT    — few-shot examples for agent prompts
    --   user_query              TEXT    — free-text query before KB search
    --   essence_query           TEXT    — constructed KB search query string
    --   essence_name            TEXT    — single essence name being looked up
    --   categoria_followup      TEXT    — follow-up prompt for a category
    --   sessions_count          INTEGER — how many times user opened the app
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

-- Fast look-up of recent/active sessions (most common access pattern)
CREATE INDEX IF NOT EXISTS idx_alchimista_sessions_updated_at
    ON alchimista_sessions (updated_at DESC);

-- Filter by path (used by analytics and routing agents)
CREATE INDEX IF NOT EXISTS idx_alchimista_sessions_chosen_path
    ON alchimista_sessions (chosen_path)
    WHERE chosen_path IS NOT NULL;

-- GIN index for JSONB columns queried by content
CREATE INDEX IF NOT EXISTS idx_alchimista_sessions_selected_chunks_gin
    ON alchimista_sessions USING GIN (selected_chunks);

CREATE INDEX IF NOT EXISTS idx_alchimista_sessions_state_gin
    ON alchimista_sessions USING GIN (state);

-- ---------------------------------------------------------------------------
-- Trigger: auto-update updated_at on every row change
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION alchimista_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_alchimista_sessions_updated_at ON alchimista_sessions;

CREATE TRIGGER trg_alchimista_sessions_updated_at
    BEFORE UPDATE ON alchimista_sessions
    FOR EACH ROW
    EXECUTE FUNCTION alchimista_set_updated_at();

-- ---------------------------------------------------------------------------
-- Function: upsert_session
--
-- Accepts a session_id and two JSON objects:
--   p_columns  — top-level column updates (key = column name, value = new value)
--   p_state    — partial JSONB merge into the `state` column
--
-- Usage from n8n HTTP Request or Supabase RPC:
--   SELECT upsert_session(
--       'sess-abc123',
--       '{"target_gender":"Donna","chosen_path":"memory"}',
--       '{"failed_iterations":3}'
--   );
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION upsert_session(
    p_session_id    TEXT,
    p_columns       JSONB  DEFAULT '{}'::JSONB,
    p_state         JSONB  DEFAULT '{}'::JSONB
)
RETURNS alchimista_sessions
LANGUAGE plpgsql
AS $$
DECLARE
    v_row alchimista_sessions;
BEGIN
    -- Insert a new row if it does not exist yet
    INSERT INTO alchimista_sessions (session_id)
    VALUES (p_session_id)
    ON CONFLICT (session_id) DO NOTHING;

    -- Apply explicit column updates via individual assignments.
    -- Only update columns present in p_columns (partial update pattern).
    UPDATE alchimista_sessions
    SET
        conversation_state   = COALESCE((p_columns->>'conversation_state'),   conversation_state),
        chosen_path          = COALESCE((p_columns->>'chosen_path'),          chosen_path),
        target_gender        = COALESCE((p_columns->>'target_gender'),        target_gender),
        perfume_type         = COALESCE((p_columns->>'perfume_type'),         perfume_type),
        default_language     = COALESCE((p_columns->>'default_language'),     default_language),
        perfume_memory       = COALESCE((p_columns->>'perfume_memory'),       perfume_memory),
        chosen_fragrance     = COALESCE((p_columns->>'chosen_fragrance'),     chosen_fragrance),
        fragrance_description= COALESCE((p_columns->>'fragrance_description'),fragrance_description),
        fragrance_notes      = COALESCE((p_columns->>'fragrance_notes'),      fragrance_notes),
        user_essence         = COALESCE((p_columns->>'user_essence'),         user_essence),
        qna_list             = COALESCE((p_columns->>'qna_list'),             qna_list),
        memory_description   = COALESCE((p_columns->>'memory_description'),   memory_description),
        enough_info          = COALESCE((p_columns->'enough_info')::BOOLEAN,  enough_info),
        selected_chunks      = CASE
                                 WHEN p_columns ? 'selected_chunks'
                                 THEN (p_columns->'selected_chunks')
                                 ELSE selected_chunks
                               END,
        blacklist_essences   = CASE
                                 WHEN p_columns ? 'blacklist_essences'
                                 THEN (p_columns->'blacklist_essences')
                                 ELSE blacklist_essences
                               END,
        perfume_name         = COALESCE((p_columns->>'perfume_name'),         perfume_name),
        name_suggestions     = CASE
                                 WHEN p_columns ? 'name_suggestions'
                                 THEN (p_columns->'name_suggestions')
                                 ELSE name_suggestions
                               END,
        should_save_name     = COALESCE((p_columns->'should_save_name')::BOOLEAN, should_save_name),
        perfume_description  = COALESCE((p_columns->>'perfume_description'),  perfume_description),
        perfume_intensity    = COALESCE((p_columns->>'perfume_intensity'),     perfume_intensity),
        general_info         = CASE
                                 WHEN p_columns ? 'general_info'
                                 THEN (p_columns->'general_info')
                                 ELSE general_info
                               END,
        -- Deep-merge JSONB state: existing keys are preserved, p_state keys overwrite
        state                = state || p_state
    WHERE session_id = p_session_id
    RETURNING * INTO v_row;

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- View: active_sessions
-- Sessions updated in the last 24 hours, ordered most-recent first.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW active_sessions AS
SELECT
    session_id,
    created_at,
    updated_at,
    chosen_path,
    conversation_state,
    target_gender,
    perfume_type,
    default_language,
    enough_info,
    jsonb_array_length(selected_chunks)   AS selected_chunks_count,
    jsonb_array_length(blacklist_essences) AS blacklisted_count,
    perfume_name,
    CASE WHEN general_info IS NOT NULL THEN TRUE ELSE FALSE END AS is_complete
FROM alchimista_sessions
WHERE updated_at >= NOW() - INTERVAL '24 hours'
ORDER BY updated_at DESC;

-- ---------------------------------------------------------------------------
-- Row-Level Security (recommended for Supabase deployments)
-- ---------------------------------------------------------------------------
ALTER TABLE alchimista_sessions ENABLE ROW LEVEL SECURITY;

-- Service-role (used by n8n via the service key) bypasses RLS automatically.
-- If you also expose this table to authenticated frontend users, add a policy:
--
-- CREATE POLICY "users_own_session" ON alchimista_sessions
--     FOR ALL
--     USING (session_id = auth.uid()::TEXT);
