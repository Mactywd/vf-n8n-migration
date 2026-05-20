## Process Selected Chunk

**Voiceflow ID:** `6888d15828d89b3c3ef205a3`

**Input variables:**
- `chunk` (string) — JSON-serialized array containing one raw KB chunk object (the first element is used)

**Output variables:**
- `content` (string) — JSON-serialized key/value object parsed from the chunk's `content` field (mapped to `final_essence`, `selectedChunk`, or `selectedEssence` depending on call-site)

**Called from:**
- `Select Essence` > node `6899f990321a340e6b77b15c`
- `JSON list to carousel with random image` > node `6889eb52b3b2df2154122c0e`
- `ROOT` > nodes `6918a6127b5346be1f7fb6f6`, `691de59f6a1baa76f9de06af`, `697dce98ca69f14640b459ed`, `697f844a5f806428bc9553bc`, `698a345ec8d59480030f0607`

### Code

```typescript
export default async function main(args) {
  try {
		const { chunk } = args.inputVars;
        const parsedChunk = JSON.parse(chunk)[0];
    
		function parseContent(contentString) {
          const fields = {};
          const pairs = contentString.split(';');
          
          pairs.forEach(pair => {
            const colonIndex = pair.indexOf(':');
            if (colonIndex > 0) {
              const key = pair.substring(0, colonIndex).trim();
              const value = pair.substring(colonIndex + 1).trim();
              fields[key] = value;
            }
          });
          
          return fields;
        }
		
		const content = parseContent(parsedChunk.content || "");
	
		return {
			outputVars: {content: JSON.stringify(content)},
			next: { path: "success" },
			trace: [
				{
					type: "debug",
					payload: { message: "Success"},
				},
			],
		};
	} catch (error) {
		return {
			next: { path: "error" },
			trace: [
				{
					type: "debug",
					payload: { message: "Error: " + error.message },
				},
			],
		};
	}
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.chunk`
- Output variables: return as `return [{ json: { content: parsedObject } }]`
- The input `chunk` is expected to be a **JSON array** — only the first element (`[0]`) is used; this is the standard Voiceflow KB response shape
- The `content` string uses semicolon-separated `Key: Value` pairs; the parser splits on `;` first, then on the first `:` — consistent with the `parseContent` helper used across multiple functions
- The output `content` is further remapped to different variable names at each call site (`final_essence`, `selectedChunk`, `selectedEssence`) — map accordingly in n8n Set nodes after the Code node
- Paths: `success` → continue, `error` → error handler
