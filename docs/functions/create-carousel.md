## Create Carousel

**Voiceflow ID:** `6885fa71436ce39aa3ac57ed`

**Input variables:**
- `finalChunks` (string) — JSON-serialized array of KB chunk objects (also aliased as `chunks` / `final_chunks` in some call-sites)
- `defaultLanguage` (string) — `italian` or `english`; controls which description field (`Contenuto` vs `Contenuto_en`) is shown

**Output variables:**
- `parsed_chunks` (array) — parsed chunk array (mapped to `parsed_chunks` in diagram)
- `carouselData` (object) — built carousel JSON (mapped to `carouselData`)
- `IDs` (array) — array of chunk IDs in the carousel (mapped to `carouselIDs`)

**Called from:**
- `JSON list to carousel with random image` > node `6885fc672ca72f007ceed588`
- `ROOT` > nodes `6948107ead131c1d706ceb3e`, `697dce43ca69f14640b452ff`

### Code

```typescript
export default async function main(args) {

    try {

        const { finalChunks, defaultLanguage } = args.inputVars;
        
        const chunks = JSON.parse(finalChunks);

        /* finalChunks is an array of objects like:
        
        {
            "score": 0.5632324,
            "documentID": "687f99a3854389cf5efea956",
            "chunkID": "303b5517-f591-4f21-9d13-0e86694b8356",
            "source": {
                "type": "table",
                "name": "Essenze",
                "rowsCount": 90
            },
            "content": "Categoria: Marina; Nome: Accord Macchia Mediterranea; Contenuto: Aromatico, Balsamico, Con sentori di mirto; Descrizione: Accordo aromatico che ricrea la macchia mediterranea selvaggia con caratteristiche balsamiche intense e sentori di mirto selvatico, note erbacee bilanciate da freschezza marina, personalità rustica e autentica che evoca coste rocciose, venti salmastri e conferisce naturalezza mediterranea con carattere territoriale distintivo; Tipo: Testa"
        }
        */

        // helper function to parse "content" into an object
        function parseContent(inputString) {
            const result = {};
            
            // Split by semicolons and process each part
            const pairs = inputString.split(';');
            
            for (let pair of pairs) {
                // Find the first colon to split key and value
                const colonIndex = pair.indexOf(':');
                if (colonIndex === -1) continue;
                
                const key = pair.substring(0, colonIndex).trim();
                const value = pair.substring(colonIndex + 1).trim();
                
                result[key] = value;
            }
            
            return result;
        }

        const carousel = { layout: "Carousel", cards: [] };

        chunks.forEach(chunk => {
            var parsedContent;
            try {
              parsedContent = parseContent(chunk.content);
            } catch (e) {
              parsedContent = chunk;
            }
            
            const title = parsedContent["Nome"] || "No Name";
            var content;
            if (defaultLanguage == "italian") {
              content = parsedContent["Contenuto"] || "No Description";
            } else {
              content = parsedContent["Contenuto_en"] || "No Description"
            }
            const imageUrl = parsedContent["Immagine"];

            // Simplified chunk for button payload
            const simplifiedChunk = {
                chunkID: chunk.chunkID,
                ...content
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
- Input variables: access as `$input.first().json.finalChunks` and `$input.first().json.defaultLanguage`
- Output variables: return as `return [{ json: { carouselData: carousel, IDs: chunkIDs, parsed_chunks: chunks } }]`
- The `trace` return with `type: "carousel"` is Voiceflow-specific; in n8n this function's output (`carouselData`) should be passed to the chat interface (e.g., via an HTTP Response node or a WhatsApp/Telegram node that renders cards)
- The `simplifiedChunk` spread bug (`...content` where `content` is a string) means card buttons currently carry only `chunkID` plus string characters as keys — this is a latent bug in the original; fix in migration by spreading `parsedContent` instead
- Language selection logic (`defaultLanguage == "italian"`) controls which description field is used; ensure `default_language` variable is correctly mapped
- Paths: `success` → continue, `error` → error handler
