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

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.current_essences` and `$input.first().json.fetched_essence`
- Output variables: return as `return [{ json: { new_essences: updatedArray } }]`
- **Syntax error**: the `return` object on lines 8–17 is missing commas between properties (`outputVars`, `next`, `trace`). This code will throw a `SyntaxError` at parse time, making the function completely non-functional. During migration, add the missing commas
- The input vars are read from `args` directly (not `args.inputVars`) — inconsistent with most other functions; correct for n8n by using `$input.first().json`
- Paths: `success` → continue (unreachable due to syntax error), `error` → error handler (always triggered)
