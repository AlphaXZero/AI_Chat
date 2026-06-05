# AI Chat

This project is a chat application (in the spirit of ChatGPT) dedicated to learning Laravel. Ask your questions, get explanations, and keep the history of your conversations so you can pick up right where you left off.

This project also serves as a learning resource: it's built step by step, and each step is documented in [`docs/tutorial.md`](docs/tutorial.md) so it can be rebuilt from scratch anytime.

## Features

- [ ] Conversational chat interface
- [ ] LLM API integration via [OpenRouter](https://openrouter.ai)
- [ ] User authentication
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
