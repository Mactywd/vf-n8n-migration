# Phase 4: Frontend Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Voiceflow widget with a custom chat interface that communicates with the n8n ROOT webhook.

**Architecture:** Minimal changes to the existing frontend — remove Voiceflow SDK, add a `ChatClient` class that handles session management and POST requests, adapt existing response rendering to the new JSON format.

**Tech Stack:** Existing frontend stack (adapt as needed), TypeScript/JavaScript, `fetch` API

**Depends on:** Phase 3 (ROOT webhook must be live and responding)  
**Required by:** nothing — this is end-user facing

---

> **Note to implementer:** This plan describes the communication layer. The UI/UX rendering (chat bubbles, typing indicator, button styles, carousel layout) should follow the existing frontend's design system. If no frontend exists yet, create a minimal HTML/CSS/JS prototype first to validate the API contract.

---

## Task 1: Remove Voiceflow SDK

- [ ] **Step 1: Find all Voiceflow references in the frontend**

```bash
grep -rn "voiceflow\|@voiceflow\|vf\." <frontend-directory> \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.html" --include="*.vue"
```

Note all files that reference Voiceflow.

- [ ] **Step 2: Remove the Voiceflow package**

```bash
npm uninstall @voiceflow/chat-widget
# or
yarn remove @voiceflow/chat-widget
```

- [ ] **Step 3: Remove all Voiceflow initialization code**

In each file found in Step 1, remove:
- `import` statements referencing `@voiceflow/...`
- Script tags loading Voiceflow from CDN
- `window.voiceflow` initialization calls
- Voiceflow-specific event listeners

- [ ] **Step 4: Verify the app still loads without errors**

```bash
npm run dev
```

Expected: app loads, no console errors about missing Voiceflow modules.

---

## Task 2: Create ChatClient

**Files:**
- Create: `src/lib/chat-client.ts` (or `.js` if no TypeScript)

- [ ] **Step 1: Write the ChatClient class**

```typescript
// src/lib/chat-client.ts

const N8N_WEBHOOK_URL = import.meta.env.VITE_N8N_WEBHOOK_URL || 'https://n8n.mattiagirellini.com/webhook/alchimista';
const SESSION_KEY = 'alchimista_session_id';
const REQUEST_TIMEOUT_MS = 115_000; // slightly under nginx 120s

export interface ChatButton {
  label: string;
  value: string;
}

export interface CarouselCard {
  title: string;
  imageUrl: string | null;
  description: string;
  categoria: string;
  tipo: string;
  button: {
    label: string;
    value: string;  // JSON string of the chunk — pass as message when user selects
  };
}

export interface ChatResponse {
  message: string;
  buttons: ChatButton[] | null;
  carousel: { layout: 'Carousel'; cards: CarouselCard[] } | null;
  current_step: string;
}

export class ChatClient {
  private sessionId: string;

  constructor() {
    this.sessionId = this.loadOrCreateSession();
  }

  private loadOrCreateSession(): string {
    let id = localStorage.getItem(SESSION_KEY);
    if (!id) {
      id = crypto.randomUUID();
      localStorage.setItem(SESSION_KEY, id);
    }
    return id;
  }

  async send(message: string): Promise<ChatResponse> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(N8N_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session_id: this.sessionId, message }),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json() as ChatResponse;
    } catch (error) {
      if ((error as Error).name === 'AbortError') {
        throw new Error('La risposta ha impiegato troppo tempo. Riprova.');
      }
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
  }

  resetSession(): void {
    localStorage.removeItem(SESSION_KEY);
    this.sessionId = this.loadOrCreateSession();
  }

  getSessionId(): string {
    return this.sessionId;
  }
}
```

- [ ] **Step 2: Add the environment variable**

In `.env` (and `.env.example`):
```
VITE_N8N_WEBHOOK_URL=https://n8n.mattiagirellini.com/webhook/alchimista
```

- [ ] **Step 3: Test ChatClient in isolation**

Open browser console on the running app and run:
```javascript
const client = new ChatClient();
const resp = await client.send('start');
console.log(resp);
```

Expected: `{ message: "Benvenuto...", buttons: [{...}, {...}], current_step: "waiting_target_gender" }`

---

## Task 3: Wire ChatClient to the existing chat UI

**Files:**
- Modify: the existing chat component (e.g., `src/components/Chat.tsx` or equivalent)

- [ ] **Step 1: Initialize ChatClient in the chat component**

```typescript
import { ChatClient } from '../lib/chat-client';

const client = new ChatClient();
```

- [ ] **Step 2: Replace the Voiceflow send handler**

Find the existing function that sends user messages (was calling Voiceflow). Replace its body with:

```typescript
async function sendMessage(text: string) {
  setIsLoading(true);
  addUserMessage(text);  // existing function to show user bubble

  try {
    const response = await client.send(text);
    addBotMessage(response.message);  // existing function to show bot bubble

    if (response.buttons) {
      showButtons(response.buttons);   // see Task 4
    }
    if (response.carousel) {
      showCarousel(response.carousel); // see Task 4
    }
  } catch (error) {
    addBotMessage((error as Error).message);
  } finally {
    setIsLoading(false);
  }
}
```

- [ ] **Step 3: Start the conversation on mount**

When the chat component mounts, send an initial message to trigger `init`:

```typescript
useEffect(() => {
  sendMessage('start');
}, []);
```

- [ ] **Step 4: Test basic conversation**

Load the app. Expected sequence:
1. Language buttons appear
2. Click "🇮🇹 Italiano" → gender question appears
3. Click a gender → path selection appears

---

## Task 4: Implement Buttons and Carousel components

**Files:**
- Create or modify: `src/components/ChatButtons.tsx`
- Create or modify: `src/components/ChatCarousel.tsx`

- [ ] **Step 1: ChatButtons component**

```typescript
// src/components/ChatButtons.tsx

interface Props {
  buttons: Array<{ label: string; value: string }>;
  onSelect: (value: string) => void;
  disabled?: boolean;
}

export function ChatButtons({ buttons, onSelect, disabled }: Props) {
  return (
    <div className="chat-buttons">
      {buttons.map((btn) => (
        <button
          key={btn.value}
          onClick={() => onSelect(btn.value)}
          disabled={disabled}
          className="chat-button"
        >
          {btn.label}
        </button>
      ))}
    </div>
  );
}
```

When a button is clicked, call `sendMessage(btn.value)` and disable all buttons to prevent double-click.

- [ ] **Step 2: ChatCarousel component**

```typescript
// src/components/ChatCarousel.tsx

interface CarouselCard {
  title: string;
  imageUrl: string | null;
  description: string;
  button: { label: string; value: string };
}

interface Props {
  cards: CarouselCard[];
  onSelect: (value: string) => void;
  disabled?: boolean;
}

export function ChatCarousel({ cards, onSelect, disabled }: Props) {
  return (
    <div className="chat-carousel">
      {cards.map((card) => (
        <div key={card.title} className="carousel-card">
          {card.imageUrl && (
            <img src={card.imageUrl} alt={card.title} className="carousel-image" />
          )}
          <h3 className="carousel-title">{card.title}</h3>
          <p className="carousel-description">{card.description}</p>
          <button
            onClick={() => onSelect(card.button.value)}
            disabled={disabled}
            className="carousel-select-button"
          >
            {card.button.label}
          </button>
        </div>
      ))}
    </div>
  );
}
```

When a carousel card is selected, call `sendMessage(card.button.value)` — `value` is the JSON chunk string that ROOT parses in `waiting_essence_selection`.

- [ ] **Step 3: Add typing indicator**

Show a "typing..." indicator while `isLoading` is true. Hide it when response arrives.

```typescript
{isLoading && <div className="typing-indicator">L'Alchimista sta pensando...</div>}
```

- [ ] **Step 4: Test buttons and carousel end-to-end**

Walk through the Memory path in the app:
1. Language buttons → click Italiano ✓
2. Gender buttons → click "Per Lei" ✓
3. Path buttons → click "Percorso della Memoria" ✓
4. Answer memory questions (3-4 turns) ✓
5. Carousel appears → click an essence ✓
6. More/done buttons appear ✓

---

## Task 5: Error handling and edge cases

**Files:**
- Modify: `src/lib/chat-client.ts`, chat component

- [ ] **Step 1: Handle timeout gracefully**

The `ChatClient.send()` already throws a user-friendly error on timeout. In the chat component, the `catch` block in Task 3 Step 2 already shows it as a bot message. Verify this by testing with a very short timeout:

Temporarily change `REQUEST_TIMEOUT_MS = 100` in `chat-client.ts`, send a message. Expected: "La risposta ha impiegato troppo tempo. Riprova." appears as a bot message. Restore the correct value.

- [ ] **Step 2: Handle network errors**

Disconnect from internet, send a message. Expected: error message appears rather than infinite loading state.

- [ ] **Step 3: Disable input while loading**

Ensure the chat input field and send button are disabled while `isLoading` is true. Prevents sending multiple messages before a response arrives.

- [ ] **Step 4: Add a restart button**

Add a small "Ricomincia" / "Start over" button that calls `client.resetSession()` and then `sendMessage('start')`.

---

## Task 6: Environment configuration for production

- [ ] **Step 1: Set production webhook URL**

In production `.env` or deployment config:
```
VITE_N8N_WEBHOOK_URL=https://n8n.mattiagirellini.com/webhook/alchimista
```

- [ ] **Step 2: Test production build**

```bash
npm run build
npm run preview
```

Walk through one complete conversation to verify no build-time issues.

- [ ] **Step 3: Commit frontend changes**

```bash
git add src/lib/chat-client.ts src/components/Chat* .env.example
git commit -m "feat: replace Voiceflow widget with n8n webhook integration"
```

---

## Phase 4 Complete — Verification Checklist

- [ ] Voiceflow SDK fully removed, no console errors
- [ ] `ChatClient` handles session persistence, timeout, network errors
- [ ] Buttons render correctly and send button `value` (not `label`) as message
- [ ] Carousel renders with images, descriptions, select button
- [ ] Carousel selection sends the chunk JSON string as message
- [ ] Typing indicator shows while loading
- [ ] Input disabled during loading
- [ ] Restart button clears session and restarts
- [ ] Full Memory path conversation works end-to-end in the browser
