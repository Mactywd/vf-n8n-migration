## Verify ID

**Voiceflow ID:** `6888cf1f28d89b3c3ef2044e`

**Input variables:**
- `message` (string) — the user's message or text to validate as a UUID

**Output variables:**
- `isSelectionValid` (string) — the trimmed UUID string if valid (only set on valid path; absent on invalid path)

**Called from:**
- Not found in diagram node references in the parsed data, but referenced conceptually in the `Select Essence` and carousel flows for validating `selectionID`

### Code

```typescript
export default async function main(args) {
    const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const message = args.inputVars.message || "";

    // Trim whitespace from the message
    const trimmedMessage = message.trim();
    
    // Check if the entire message matches the UUID pattern
    if (uuidPattern.test(trimmedMessage)) {
        return {
			outputVars: {isSelectionValid: trimmedMessage},
			next: { path: "valid" },
			trace: [
				{
					type: "debug",
					payload: { message: "Valid UUID"},
				},
			],
		};
    } else {
        return {
			next: { path: "invalid" },
			trace: [
				{
					type: "debug",
					payload: { message: "Invalid UUID" },
				},
			],
		};
    }
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.message`
- Output variables: on valid path return `return [{ json: { isSelectionValid: trimmedMessage } }]`; on invalid path route to error branch
- The UUID pattern is RFC 4122-compliant (`/^[0-9a-f]{8}-...-[0-9a-f]{12}$/i`)
- In Voiceflow, the `valid`/`invalid` port names control flow routing; in n8n use an If node after the Code node to branch on `isSelectionValid` presence or a boolean flag
- The function validates the **entire** message string (after trim) must be a UUID — there is no substring extraction; if the user types anything besides a bare UUID it routes to `invalid`
- Paths: `valid` → proceed with selection, `invalid` → re-prompt user
