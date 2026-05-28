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
