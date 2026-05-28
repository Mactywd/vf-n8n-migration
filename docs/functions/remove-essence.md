## Remove Essence

**Voiceflow ID:** `68908b0817643c0ee1a25757`

**Input variables:**
- `selectedEssence` (string) — JSON-serialized essence object to remove (matched by `Nome` field)
- `selectedChunks` (string) — JSON-serialized array of currently selected essence objects

**Output variables:**
- `filteredChunks` (string) — JSON-serialized array with the specified essence removed (mapped to `selectedChunks`)

**Called from:**
- `ROOT` > nodes `68908b05de05ba6c49d680b4`, `697f844a5f806428bc9553b7`

### Code

```typescript
export default async function main(args) {
	try {
		const { selectedEssence, selectedChunks } = args.inputVars;

		const parsedChunks = JSON.parse(selectedChunks);
		const parsedEssence = JSON.parse(selectedEssence);

		const content = parsedEssence
		
		var indexToRemove = -1
		parsedChunks.forEach(function(chunk, index) {
			if (chunk.Nome == content.Nome) {
				indexToRemove = index
			}
		})

		if (indexToRemove == -1) {
			throw Error("Essence to remove not in selection")
		}

		parsedChunks.splice(indexToRemove, 1)

		return {
			outputVars: { filteredChunks: JSON.stringify(parsedChunks) },
			next: { path: "success" },
			trace: [
				{
					type: "debug",
					payload: { message: "Removed index " + indexToRemove + " with name " + content.Nome },
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
