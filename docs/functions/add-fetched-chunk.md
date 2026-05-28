## Add Fetched Chunk

**Voiceflow ID:** `6893b57b436f32cabf66ea8e`

**Input variables:**
- `current_essences` (string) — JSON-serialized array of already-fetched essence chunks
- `fetched_essence` (string) — JSON-serialized single essence chunk object to append

**Output variables:**
- `new_essences` (array) — updated array with the new chunk appended

**Called from:** Not found in any active diagram node (function exists but has no call-site references in parsed diagrams — may be unused or superseded)

### Code

```typescript
export default async function main(args) {
try {
  const { current_essences, fetched_essence } = args;
  const parsedEssences = JSON.parse(current_essences)
  const parsedEssence = JSON.parse(fetched_essence)

  parsedEssences.push(parsedEssence)
  
  return {
    outputVars: {new_essences: parsedEssences}
    next: { path: "success"}
    trace: [
      {
        type: "debug",
        payload: {
          message: `gud`,
        },
      },
    ],
  };
} catch (error) {
  return {
    next: { path: "error"},
    trace: [
      {
        type: "debug",
        payload: {
          message: "Error: " + error.message
        }
      }
    ]
  }
}
}
```
