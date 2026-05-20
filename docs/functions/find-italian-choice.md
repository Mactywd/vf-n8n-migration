## Find Italian Choice

**Voiceflow ID:** `690f62b96076dd72b3b07ee2`

**Input variables:**
- `italian_labels` (string) — comma-separated list of Italian button labels
- `english_labels` (string) — comma-separated list of English button labels (positionally aligned with `italian_labels`)
- `last_utterance` (string) — the user's selected label (may be in either language)

**Output variables:**
- `final_label` (string) — the canonical Italian label (if input was English, returns the Italian equivalent; if already Italian or unknown, returns the original value)

**Called from:**
- `Show Lamguage Buttons` diagram > node `690f62abc501166d01775a18`

### Code

```typescript
export default async function main(args) {
try {
    var { italian_labels, english_labels, last_utterance } = args.inputVars;
    var final_label = last_utterance;

    italian_labels = italian_labels.split(",")
    english_labels = english_labels.split(",")
  
    // If label was in english, find italian equivalent
    if (english_labels.includes(last_utterance)) {    
        let index = english_labels.indexOf(last_utterance);
        final_label = italian_labels[index];
    }

    return {
        next: { path: "success" },
        outputVars: { final_label: final_label },
        trace: [
            {
                type: "debug",
                payload: {
                    message: `Final label: ${final_label}, English Labels: ${english_labels}`,
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
                    message: error.message,
                },
            },
        ],
    };
}
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.italian_labels`, `$input.first().json.english_labels`, `$input.first().json.last_utterance`
- Output variables: return as `return [{ json: { final_label } }]`
- This function normalizes multi-language user input back to the canonical Italian label for downstream conditional logic — always call it after `Show Languaged Buttons` captures the user's choice
- The Italian and English lists must be positionally aligned (same length, same order) — validate upstream that both label strings have matching comma counts
- If `last_utterance` is already an Italian label (not found in `english_labels`), `final_label` is returned unchanged — this is the pass-through case for Italian-speaking users
- Paths: `success` → continue, `error` → error handler
