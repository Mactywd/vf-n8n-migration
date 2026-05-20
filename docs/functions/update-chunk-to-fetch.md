## Update Chunk to Fetch

**Voiceflow ID:** `6893b2f8436f32cabf66e97a`

**Input variables:**
- `final_essences` (string) — JSON-serialized array of all essence objects to paginate through
- `currentEssenceIndex` (number or string) — current pagination cursor (zero-based index)

**Output variables:**
- `currentEssence` (string) — JSON-serialized essence object at `currentEssenceIndex`
- `newEssenceIndex` (number) — incremented index for the next call

**Called from:** Not found in any active diagram node (function exists but has no call-site references in parsed diagrams — may be unused or replaced)

### Code

```typescript
export default async function main(args) {
try {
    const { final_essences, currentEssenceIndex } = args;

    throw Error(final_essences)
  
    const parsedEssences = JSON.parse(final_essences);
    let newEssenceIndex = parseInt(currentEssenceIndex);
    
    // Check bounds
    if (newEssenceIndex >= parsedEssences.length) {
      throw new Error("Index out of bounds");
    }
    
    const currentEssence = JSON.stringify(parsedEssences[newEssenceIndex]);
    newEssenceIndex = newEssenceIndex + 1; // Fixed: use the parsed integer
    
    return {
      outputVars: {currentEssence: currentEssence, newEssenceIndex: newEssenceIndex},
      next: { path: "success"}, // Added missing comma
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
- Input variables: access as `$input.first().json.final_essences` and `$input.first().json.currentEssenceIndex`
- Output variables: return as `return [{ json: { currentEssence, newEssenceIndex } }]`
- **Critical bug**: line 4 contains `throw Error(final_essences)` — this immediately throws on every call, making the function always fall through to the `error` path. The actual pagination logic (lines 5 onward) is unreachable dead code. During migration, **remove the `throw` statement**
- The input vars are read from `args` directly (not `args.inputVars`) — this is inconsistent with other functions; in n8n the Code node receives a single `$input` regardless
- Paths: `success` → continue (currently unreachable), `error` → error handler (always triggered due to the bug)
