## Remove Chosen Essences

**Voiceflow ID:** `688a0f7b34582772f5ad5498`

**Input variables:**
- `selectedChunks` (string) — JSON-serialized array of already-selected essence objects
- `blacklistEssences` (string) — JSON-serialized array of blacklisted chunk objects (may be raw KB chunks with a `content` field, or already-parsed objects)
- `kbChunks` (string) — JSON-serialized array of new KB search result chunks to filter
- `beforeAltro` (string) — additional filter input (used in some call-sites; exact purpose unclear from code — passed via inputMapping but not destructured in the function body)
- `prevCarousel` (string) — previous carousel data (used in some call-sites; passed via inputMapping but not destructured in the function body)

**Output variables:**
- `processedChunks` (string) — JSON-serialized array of `kbChunks` with selected and blacklisted essences removed (mapped to `kb_results`)

**Called from:**
- `KB Search` > node `68934c0c87710eb03daf29bd`

### Code

```typescript
export default async function main(args) {
  try {
    let { selectedChunks, kbChunks, blacklistEssences } = args.inputVars;

    selectedChunks = JSON.parse(selectedChunks);
    blacklistEssences = JSON.parse(blacklistEssences);
    kbChunks = JSON.parse(kbChunks);

    function parseContent(content) {
      const contentParts = content.split(";").map(part => part.trim());
      const contentObject = {};
      contentParts.forEach(part => {
        const [key, value] = part.split(":").map(p => p.trim());
        if (key && value) {
          contentObject[key] = value;
        }
      });
      return contentObject;
    }

    const processedChunks = [];

    kbChunks.forEach((kbChunk) => {
      const kbContent = parseContent(kbChunk.content);
      let isSelected = false;

      // check against selectedChunks
      selectedChunks.forEach((selectedChunk) => {
        if (kbContent.Nome === selectedChunk.Nome) {
          isSelected = true;
        }
      });

      // check against blacklistEssences (parse their content!)
      blacklistEssences.forEach((blacklistedEssence) => {
        try {
            var blContent = parseContent(blacklistedEssence.content);
        } catch (e) {
            var blContent = blacklistedEssence
        } // if error is thrown it means it is already parsed

        if (kbContent.Nome === blContent.Nome) {
          isSelected = true;
        }
      });

      if (!isSelected) {
        processedChunks.push(kbChunk);
      }
    });

    return {
      outputVars: { processedChunks: JSON.stringify(processedChunks) },
      next: { path: "success" },
      trace: [
        {
          type: "debug",
          payload: { message: `Success` },
        },
      ],
    };
  } catch (error) {
    return {
      outputVars: {},
      next: { path: "error" },
      trace: [
        {
          type: "debug",
          payload: { message: `Error: ${error.message}` },
        },
      ],
    };
  }
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.selectedChunks`, `$input.first().json.kbChunks`, `$input.first().json.blacklistEssences`
- Output variables: return as `return [{ json: { processedChunks } }]`
- This function is the de-duplication gate in the KB Search loop — it removes already-selected and blacklisted essences from fresh KB results before showing them to the user
- The `blacklistEssences` handling has a dual-format try/catch: if `blacklistedEssence.content` exists it parses it; otherwise treats the object as already parsed — replicate this defensive logic in n8n
- Note: `beforeAltro` and `prevCarousel` appear in the inputMapping of some call-sites but are not used in the function body — they are safe to ignore during migration
- The `parseContent` helper uses `split(":")` on each pair (not `indexOf(":")`) — this means values containing `:` get truncated; a known limitation of the original implementation
- Paths: `success` → continue, `error` → error handler
