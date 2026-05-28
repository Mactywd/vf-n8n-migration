## Add Essence to Selection

**Voiceflow ID:** `68c0731e64b6a42fb8cf99c7`

**Input variables:**
- `selectedChunks` (string) — JSON-serialized array of already-selected essence objects
- `selectedChunk` (string) — JSON-serialized single essence object to add

**Output variables:**
- `selectedChunks` (string) — updated JSON-serialized array with the new essence appended (mapped to `selectedChunks`)
- `selectedChunksLength` (number) — new total count (mapped to `selectedChunksLength` and `current_fragrance_essence`)

**Called from:**
- `JSON list to carousel with random image` > node `68c0731aef2055ba016de11d`
- `ROOT` > nodes `68fcfc33c916fb912a912a9a`, `691de5406a1baa76f9de012d`, `697dce98ca69f14640b459f2`

### Code

```typescript
export default async function main(args) {
    var {selectedChunks, selectedChunk} = args.inputVars 
    selectedChunks = JSON.parse(selectedChunks)
    selectedChunk = JSON.parse(selectedChunk)

    selectedChunks.push(selectedChunk)
    const selectedChunksLength = selectedChunks.length

    selectedChunks = JSON.stringify(selectedChunks)

    return {
        outputVars: {selectedChunks, selectedChunksLength},
        trace: [
            {
                type: "debug",
                payload: {
                    message: `Added chunk. Total selected chunks: ${selectedChunksLength}`,
                }
            }
        ]
    }
}
```
