# Generic AI Chat

This project is a chat application (in the spirit of ChatGPT) dedicated to learning Laravel. Ask your questions, get explanations, and keep the history of your conversations so you can pick up right where you left off.

This project also serves as a learning resource: it's built step by step, and each step is documented in [`docs/tutorial.md`](docs/tutorial.md) so it can be rebuilt from scratch anytime.

## TO DO list

- [X] LLM API integration via [OpenRouter](https://openrouter.ai)
- [ ] change the theme when become crazy in more lovercraftian theme
- [ ] normal title wich transforms in anormal more and more when reaching 5/5 insanity
- [ ] changing bg more and more to be more lovecraftia
- [ ] redirect when suppr + change alert
- [ ] make seeder and factory
- [ ] merge services
- [ ] update homepage
- [ ] ceck vue
- [ ] add conversatoin delete
- [ ] avoid scrolling history while scrolling
- [ ] scroll to bottom when new message is received or when the user open a old conversation
- [ ]  update favorite ia with @change on select
- [ ] show the user message before response instead of user message and chat response simultanusly
- [ ] enter key to chat
- [ ] multiple systems prompts
- [ ] handle error
- [ ] profile picture becoming altered with every prompts
- [ ] ia becoming bored and angry with every prompts
- [ ] Change API url ?
- [ ] auto scroll when 
- [ ] enter to confirm question
- [ ] navbar history
- [ ] typerarea below questions
- [ ] Update simpleaskservice (favorite ia) ?
- [x] check route in routes/web.php
- [ ] look further js/components/MarkdownRenderer.vue
- [ ] fix warning simpleaskservice
- [ ] look further the contoler
- [ ] Mark down answer (course)
- [ ] Conversational chat interface
- [ ] Conversation history (stored in the database)
- [ ] Resume and manage past conversations
- [ ] Streaming responses (rendered as they are generated)


## Tech stack

| Layer | Technology |
|---|---|
| Back-end | Laravel (PHP 8.2+) |
| Front-end | Vue 3 + Inertia.js |
| Build | Vite |
| Database | MySQL / SQLite |
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
cd laralearn

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


## 📖 Documentation

The full step-by-step tutorial explaining how the project is built lives in [`docs/tutorial.md`](docs/tutorial.md).
