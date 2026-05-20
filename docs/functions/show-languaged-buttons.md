## Show Languaged Buttons

**Voiceflow ID:** `690f603f6076dd72b3b07e37`

**Input variables:**
- `italian_labels` (string) — comma-separated list of button labels in Italian
- `english_labels` (string) — comma-separated list of button labels in English
- `default_language` (string) — `italian` or anything else (defaults to English)

**Output variables:** *(none — renders via Voiceflow trace directly)*

**Called from:**
- `Show Lamguage Buttons` diagram > node `690f601ec501166d01775a02`

### Code

```typescript
export default async function main(args) {
	try {
		var { italian_labels, english_labels, default_language } = args.inputVars;

        let labelsToUse = default_language === 'italian' ? italian_labels : english_labels;
        const parsedNames = labelsToUse.split(",")

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
- Input variables: access as `$input.first().json.italian_labels`, `$input.first().json.english_labels`, `$input.first().json.default_language`
- Output: return button array as `return [{ json: { buttons } }]` and pass to the messaging platform's button/quick-reply node
- Labels are comma-separated plain strings (no JSON serialization) — ensure the upstream variable is formatted as `"Label1,Label2,Label3"` with no extra spaces around commas (or trim after split)
- The language check is strict equality `=== 'italian'`; any other value (including `'it'`) defaults to English — verify the `default_language` variable value format in the migration
- This function is the localization-aware version of `Show Buttons`; `Show Buttons` receives a JSON array while this function receives two parallel comma-separated strings
- No output variable mapping in diagram — purely trace-based rendering
