## Create generalInfo

**Voiceflow ID:** `6893a754436f32cabf66e21e`

**Input variables:**
- `perfumeName` (string) — user's chosen name for their perfume
- `selectedChunks` (string) — JSON-serialized array of selected essence objects (each with a `Nome` field)
- `intensifiedCategory` (string, optional) — essence category chosen for intensification (also seen as `intensifiedEssence` in inputMapping)
- `perfumeIntensity` (string) — chosen intensity level
- `fragranceDescription` (string) — AI-generated or user-provided fragrance description
- `targetGender` (string) — `Uomo` / `Donna` / `Unisex`
- `chosenPath` (string) — `memory` / `inspiration` / `renaissance`
- `pathInfoField` (string) — label for the path-specific input field
- `pathInfoValue` (string) — value for the path-specific input (e.g., the referenced perfume name, or memory text)
- `additionalNotes` (string) — any extra notes from the user

**Output variables:**
- `generalInfo` (string) — JSON-serialized summary object containing all of the above fields (mapped to `generalInfo`)

**Called from:**
- `ROOT` > node `6893a723326075ddd982182e`

### Code

```typescript
export default async function main(args) {

	const { inputVars } = args;

	try {
		const generalInfo = {};

		// Perfume Name
		generalInfo.perfumeName = inputVars.perfumeName;

		// Essences (Notes)
		const parsedChunks = JSON.parse(inputVars.selectedChunks);
		const noteNames = parsedChunks.map(chunk => chunk.Nome).filter(name => name);
		generalInfo.notes = noteNames;

		// Intensified Category
        generalInfo.intensifiedCategory = inputVars.intensifiedCategory || null

		// Perfume Intensity
		generalInfo.perfumeIntensity = inputVars.perfumeIntensity;

		// Fragrance Description
		generalInfo.fragranceDescription = inputVars.fragranceDescription;

        // Target Gender
        generalInfo.targetGender = inputVars.targetGender

        // Chosen Path
        generalInfo.chosenPath = inputVars.chosenPath

        // Path info Field
        generalInfo.pathInfoField = inputVars.pathInfoField
        
		// Path info Value
		generalInfo.pathInfoValue = inputVars.pathInfoValue

		// Additional Notes
		generalInfo.additionalNotes = inputVars.additionalNotes;
      
		return {
			outputVars: { generalInfo: JSON.stringify(generalInfo) },
			trace: [
				{
					type: "debug",
					payload: {
						message: "Successfully created generalInfo",
						data: generalInfo
					}
				}
			]
		};

	} catch (error) {
		return {
			outputVars: { generalInfo: JSON.stringify({}) },
			trace: [
				{
					type: "error",
					payload: {
						message: `Error in main function: ${error.message}`,
						stack: error.stack
					}
				}
			]
		};
	}
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access all from `$input.first().json.*` (e.g. `$input.first().json.perfumeName`)
- Output variables: return as `return [{ json: { generalInfo: JSON.stringify(generalInfo) } }]`
- This is the **final assembly step** of the creation journey — called once at `Finish Perfume Creation` in ROOT; its output (`generalInfo`) is the structured payload sent to the perfumer or stored for order fulfillment
- The `notes` field extracts only the `Nome` property from each selected chunk — ensure all chunks in `selectedChunks` have been through `Process Selected Chunk` or `Post Process Essences` before this function runs
- `intensifiedCategory` input appears as `intensifiedEssence` in some inputMappings but the code reads it as `inputVars.intensifiedCategory` — pass it under the correct key
- On error, returns an empty `{}` object rather than throwing — the workflow continues silently; add explicit error logging in n8n if needed
- No `next` path ports used — single output path only
