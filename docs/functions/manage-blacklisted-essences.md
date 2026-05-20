## Manage Blacklisted Essences

**Voiceflow ID:** `68d43c2f7fe5c16f8da8f363`

**Input variables:**
- `blacklistEssences` (string) — JSON-serialized array of currently blacklisted chunk objects
- `newEssences` (string) — JSON-serialized array of new chunk objects to process
- `action` (string) — operation to perform: `"add"` to append new essences to the blacklist, `"reset"` to clear it

**Output variables:**
- `updatedEssences` (string) — JSON-serialized updated blacklist array (mapped to `blacklistEssences`)

**Called from:**
- `JSON list to carousel with random image` > node `68d43c9dcc66e9190de505bd`

### Code

```typescript
export default async function main(args) {
  try {
		const { blacklistEssences, newEssences, action } = args.inputVars;

        function parseContent(inputString) {
            const result = {};
            
            // Split by semicolons and process each part
            const pairs = inputString.split(';');
            
            for (let pair of pairs) {
                // Find the first colon to split key and value
                const colonIndex = pair.indexOf(':');
                if (colonIndex === -1) continue;
                
                const key = pair.substring(0, colonIndex).trim();
                const value = pair.substring(colonIndex + 1).trim();
                
                result[key] = value;
            }
            
            return result;
        }
    
        var blacklist = JSON.parse(blacklistEssences);
        const essences = JSON.parse(newEssences);

        var parsedEssences = []
            essences.forEach((item)=> {
                parsedEssences.push(parseContent(item.content));
        })
        var parsedBlacklist = []
            blacklist.forEach((item)=> {
                parsedBlacklist.push(parseContent(item.content));
        })
    
        if (action === "reset") {
            return {
                outputVars: { updatedEssences: JSON.stringify([]) },
                next: { path: "success" },
                trace: [
                    {
                        type: "debug",
                        payload: { message: "Essences reset to empty list" },
                    },
                ],
            };
        } else if (action === "add") {

            const updatedEssences = [...parsedEssences, ...parsedBlacklist];

            return {
                outputVars: { updatedEssences: JSON.stringify(updatedEssences) },
                next: { path: "success" },
                trace: [
                    {
                        type: "debug",
                        payload: { message: "Essences updated by removing blacklisted items" },
                    },
                ],
            };
        } else {
            throw new Error("Invalid action specified");
        }
        
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
- Input variables: access as `$input.first().json.blacklistEssences`, `$input.first().json.newEssences`, `$input.first().json.action`
- Output variables: return as `return [{ json: { updatedEssences } }]`
- Note a potential bug in the original: the `add` action debug message says "removing blacklisted items" but actually **adds** new essences to the blacklist (concatenates `parsedEssences` + `parsedBlacklist`); the description is misleading
- Both `newEssences` and `blacklistEssences` are parsed from raw KB chunks (with `item.content` field) — the function always re-parses both lists; there is no "already parsed" fallback unlike in `Remove Chosen Essences`
- In the `reset` action, `newEssences` and `blacklistEssences` are still JSON-parsed (lines before the if/else) even though their values are discarded — ensure valid JSON is always passed even when resetting
- The output variable `updatedEssences` is mapped back to `blacklistEssences` in the diagram (and one typo variant `updatesEssences` also maps to `blacklistEssences`)
- Paths: `success` → continue, `error` → error handler
