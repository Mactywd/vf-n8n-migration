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
