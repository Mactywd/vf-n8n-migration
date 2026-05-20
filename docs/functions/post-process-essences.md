## Post Process Essences

**Voiceflow ID:** `6899c2130a2a1fc690dab147`

**Input variables:**
- `essences` (string or object) — KB search result; either a JSON string with a `.chunks` array or a direct array of chunk objects
- `essenceNames` (string) — comma-separated list of essence names to match (case-insensitive, normalized)

**Output variables:**
- `rightChunks` (string) — JSON-serialized array of chunks whose `Nome` matches the requested essence names (mapped to `final_chunks`, `bypass_kbsearch_chunks`, `final_essence`, `selectedChunk`, `selectedEssence`)
- `excludedChunks` (string) — JSON-serialized array of chunks that did NOT match (mapped to `blacklistEssences`, `temp_variable`)

**Called from:**
- `Select Essence` > node `6899f982321a340e6b77b14f`
- `JSON list to carousel with random image` > node `6899f6d1321a340e6b77a536`
- `KB Search` > node `6899c21275c76d52737df62b`
- `ROOT` > nodes `68c2d87390aacf5de898489b`, `68fcfa8ac916fb912a9128a4`, `6918a6127b5346be1f7fb6fb`, `691de5996a1baa76f9de06a3`, `697dce98ca69f14640b459e8`, `697f844a5f806428bc9553c1`

### Code

```typescript
export default async function main(args) {
  // Normalizza whitespace e apostrofi
  function normalizeText(str) {
    if (!str) return str;
    return str
      // Normalizza tutti i tipi di whitespace in spazi normali
      .replace(/\s+/g, ' ')
      // Normalizza tutti i tipi di apostrofi/virgolette singole in apostrofo standard
      .replace(/[‘’‚‛′‵ʼ]/g, "'")
      .trim();
  }

  function parseContentString(contentString) {
    const fields = {};
    const pairs = contentString.split(';');
    
    pairs.forEach(pair => {
      const colonIndex = pair.indexOf(':');
      if (colonIndex > 0) {
        const key = pair.substring(0, colonIndex).trim();
        const value = normalizeText(pair.substring(colonIndex + 1).trim());
        fields[key] = value;
      }
    });
    return fields;
  }

  try {
    var { essences, essenceNames } = args.inputVars;
    
    // Parse essence names con normalizzazione
    essenceNames = essenceNames.split(",").map((essence) => 
      normalizeText(essence).toLowerCase()
    );
    
    var chunksArray;
    
    if (typeof essences === 'string') {
      try {
        var parsed = JSON.parse(essences);
        if (parsed && parsed.chunks && Array.isArray(parsed.chunks)) {
          chunksArray = parsed.chunks;
        } else if (Array.isArray(parsed)) {
          chunksArray = parsed;
        } else {
          throw new Error("Parsed data is not in expected format");
        }
      } catch (parseError) {
        throw new Error("Failed to parse essences string: " + parseError.message + " | Essences value: " + essences);
      }
    } else if (typeof essences === 'object') {
      if (essences.chunks && Array.isArray(essences.chunks)) {
        chunksArray = essences.chunks;
      } else if (Array.isArray(essences)) {
        chunksArray = essences;
      } else {
        throw new Error("Essences object does not contain valid chunks array");
      }
    } else {
      throw new Error("Essences is neither string nor object: " + typeof essences);
    }
    
    var rightChunks = [];
    var excludedChunks = [];

    chunksArray.forEach((chunk) => {
      const parsedFields = parseContentString(chunk.content);
      const nome = normalizeText(parsedFields.Nome).toLowerCase();

      if (essenceNames.includes(nome)) {
        rightChunks.push(chunk);
      } else {
        excludedChunks.push(chunk);
      }
    });

    if (rightChunks.length === 0) {
      throw new Error("No matching essences found. Looking for: " + essenceNames.join(', '));
    }
    
    return {
      next: { path: "success" },
      outputVars: {
        rightChunks: JSON.stringify(rightChunks),
        excludedChunks: JSON.stringify(excludedChunks),
      },
      trace: [
        {
          type: "debug",
          payload: {
            message: `Found ${rightChunks.length} out of ${essenceNames.length} requested essences: ${rightChunks.map(chunk => parseContentString(chunk.content).Nome).join(', ')}`,
          },
        },
      ],
    };
  } catch (error) {
    return {
      next: { path: "error" },
      trace: [
        {
          type: "debug",
          payload: {
            message: "Error occurred: " + error.message
          }
        }
      ]
    }
  }
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.essences` and `$input.first().json.essenceNames`
- Output variables: return as `return [{ json: { rightChunks, excludedChunks } }]`
- This is the most widely-called function (10+ call sites across 4 diagrams) — it acts as the filter/router between the AI agent's named essence recommendations and the raw KB results
- The `normalizeText` helper handles Unicode whitespace and curly-apostrophe variants (common in Italian text) — replicate this normalization in n8n
- The `essences` input accepts multiple formats (raw array, `{ chunks: [...] }` object, JSON string of either) — handle all three shapes in the n8n Code node
- `rightChunks` output is mapped to many different variable names at different call sites; use n8n Set nodes after the Code node to assign to the correct workflow variable
- Throws (goes to `error` path) if zero matching chunks are found — this is a valid exit condition when an AI-suggested essence name doesn't exist in the KB
- Paths: `success` → continue, `error` → error handler
