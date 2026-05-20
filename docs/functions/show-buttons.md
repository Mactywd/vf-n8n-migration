## Show Buttons

**Voiceflow ID:** `689080ba17643c0ee1a253da`

**Input variables:**
- `labels` (string) — JSON-serialized array of label strings to render as buttons

**Output variables:** *(none — renders via Voiceflow trace directly)*

**Called from:**
- `KB Search` > node `693d7edf7f25f5a43c236408`
- `ROOT` > nodes `689080b3f663d4321c75612a`, `68a2fbf49d7be321cb81ce31`, `68c1e8b4d5a168dd97b9d78c`, `68c1ea37d5a168dd97b9d7c2`, `693d84677f25f5a43c236f1d`

### Code

```typescript
export default async function main(args) {
	try {
		const { labels } = args.inputVars;

        const parsedNames = JSON.parse(labels);
      
		const buttons = parsedNames.map((label) => {
			return {
				name: label,
				request: {
					type: "intent",
					payload: {
						label: label,
					},
				},
			};
		});

		return {
			trace: [
				{
					type: "choice",
					payload: {
						buttons: buttons,
					},
				},
			],
		};
	} catch (error) {
		return {
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
- Input variables: access as `$input.first().json.labels`
- Output: the `buttons` array should be returned as `return [{ json: { buttons } }]` and forwarded to the chat interface node
- The `type: "choice"` trace is Voiceflow-specific; in n8n map to quick-reply buttons in the messaging platform (WhatsApp list/button message, Telegram inline keyboard, etc.)
- Each button carries only a `label` in its intent payload — no entity data; this is a simpler variant compared to carousel buttons
- No output variable mapping in diagram (pure trace-based rendering); the user's response is captured by the next `capture-v3` / webhook wait node
