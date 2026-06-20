# Chat Normal

A Laravel-based chat application with a twist: the AI starts perfectly sane, but the longer you talk to it, the more it descends into madness — à la Lovecraft. Watch the interface transform as the AI loses its mind.

This project also serves as a personal learning resource: it's built step by step, and each step is documented in [`docs/tutorial.md`](docs/tutorial.md) so it can be rebuilt from scratch anytime.

## Features

- **Streaming responses** — answers appear token by token as they are generated
- **Conversation history** — all exchanges are stored in the database and resumable at any time
- **Auto-generated titles** — each conversation gets a short title generated from the first message
- **Model selector** — choose any model available on OpenRouter
- **Custom instructions** — configure the assistant's tone, emoji usage, response length, and personal shortcuts (`/command` → expanded instruction)
- **Favorite model** — set a default model per conversation or globally in settings
- **Progressive insanity** — the AI's behaviour and the UI both evolve with each exchange: the title shifts from "CHAT NORMAL" to "CHAT ANORMAL", a red vignette creeps in, and the background eventually breaks into a glitched checkerboard

## TO DO list

- [x] LLM API integration via OpenRouter
- [x] update readme
- [x] error manage
- [x] generate title avec gemini-2.5-flash-lite, basé uniquement sur le message user pour de meilleures performances
- [x] verify ai settings default
- [x] adding favorite IA in modal settings
- [x] adapt style on other pages
- [x] change the theme when become crazy (vignette rouge, damier mauve, titre qui rougit)
- [x] normal title which transforms in anormal more and more when reaching insanity 5+
- [x] changing bg more and more to be more lovecraftian (reality-broken checkerboard)
- [x] redirect when suppr + change alert (delete fonctionne mais alert native pas encore remplacée)
- [ ] make seeder and factory (factories créées, seeders vides)
- [x] merge services (BaseAskService + héritage)
- [x] update homepage (Welcome.vue restyled)
- [x] check vue
- [x] add conversation delete
- [x] avoid scrolling history while scrolling (auto-scroll implémenté)
- [x] scroll to bottom when new message is received or when the user open a old conversation
- [x] update favorite ia with @change on select (via AiSettingsModal)
- [x] show the user message before response (pendingUserMessage)
- [x] enter key to chat
- [x] handle error (bulle rouge + détection [ERROR] dans le flux)
- [x] ia becoming bored and angry with every prompts
- [x] Change API url
- [x] auto scroll
- [x] enter to confirm question
- [x] navbar history (sidebar avec liste des conversations)
- [x] textarea below questions (zone de saisie fixe en bas)
- [x] check route in routes/web.php
- [ ] look further js/components/MarkdownRenderer.vue
- [x] fix warning simpleaskservice
- [x] look further the controller
- [x] Markdown answer
- [x] Conversational chat interface
- [x] Conversation history (stored in the database)
- [x] Resume and manage past conversations
- [x] Streaming responses (rendered as they are generated)

## Tech stack

| Layer | Technology |
|---|---|
| Back-end | Laravel 13.13 (PHP 8.2+) |
| Front-end | Vue 3.5 + Inertia.js (Composition API) |
| Build | Vite |
| Database | SQLite (local) / PostgreSQL (production) |
| Styling | Tailwind CSS + shadcn-vue |
| AI | OpenRouter API |
| Testing | Pest |

## Requirements

- PHP 8.2 or higher
- Composer
- Node.js and npm
- An [OpenRouter](https://openrouter.ai/keys) API key

## Installation

Clone the repository and install the dependencies:

```bash
git clone <repository-url>
cd chat-normal
composer install
npm install
```

Copy the environment file and generate the application key:

```bash
cp .env.example .env
php artisan key:generate
```

Add your OpenRouter key to the `.env` file:

```env
OPENROUTER_API_KEY=your_key_here
```

Configure the database in `.env`, then run the migrations:

```bash
php artisan migrate
```

## Running the project

### Standard method

```bash
php artisan serve   # back-end
npm run dev         # front-end (second terminal)
```

### Quick method

```bash
composer run dev
```
