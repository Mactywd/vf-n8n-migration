## Create Essence Buttons

**Voiceflow ID:** `688f333c17643c0ee1a20087`

**Input variables:**
- `selectedChunks` (string) — JSON-serialized array of already-parsed essence objects (each with `Nome`, `Contenuto`, `Immagine` keys)

**Output variables:** *(none — renders via Voiceflow trace directly)*

**Called from:**
- `Select Essence` > node `688f34bc36d5ca4fd32d10c6`
- `ROOT` > node `6918a6127b5346be1f7fb706`, `697f844a5f806428bc9553d1`

### Code

```typescript
export default async function main(args) {
    try {

        const { selectedChunks } = args.inputVars;
        
        const chunks = JSON.parse(selectedChunks);

        const carousel = { layout: "Carousel", cards: [] };

        chunks.forEach(chunk => {
            const parsedContent = chunk
            
            const title = parsedContent["Nome"] || "No Name";
            const content = parsedContent["Contenuto"] || "No Description";
            const imageUrl = parsedContent["Immagine"];

            // Simplified chunk for button payload
            const simplifiedChunk = {
                ...chunk
            }

            carousel.cards.push({
                title: title,
                imageUrl: imageUrl,
                description: {
                    text: content,
                    slate: [
                        { children: [{ text: content }] }
                    ]
                },
                buttons: [
                    {
                        name: title,
                        request: {
                            type: "intent",
                            payload: {
                                intent: {
                                    name: "select_essence"
                                },
                                entities: [
                                    {
                                        name: "selectedChunk",
                                        value: JSON.stringify(simplifiedChunk)
                                    }
                                ],
                                query: title
                            }
                        },
                        payload: {
                            label: title
                        }
                    }
                ]
            });
        });

        return {
            next: { path: "success" },
            trace: [
                {
                    type: "carousel",
                    payload: carousel,
                },
            ],
        };
    } catch (error) {
        return {
            next: { path: "error" },
            trace: [
                {
                    type: "debug",
                    payload: { message: "Error: " + error.message },
                },
            ],
        };
    }
}
```

### n8n Migration Notes

- Map to: Code node (JavaScript mode)
- Input variables: access as `$input.first().json.selectedChunks`
- Output: the carousel object should be passed to the UI layer — in n8n, return it as `return [{ json: { carousel } }]` and send via HTTP Response / chat node
- Unlike `Create Carousel`, this function operates on **already-parsed** essence objects (not raw KB chunks), so there is no `parseContent` step
- The `select_essence` intent entity payload (`selectedChunk`) embeds the full chunk JSON — in n8n this maps to a button action that carries the chosen essence in its payload
- Paths: `success` → continue, `error` → error handler
