# Tutorial laravel + vue

This tutorial documents how the project is built, so it can be rebuilt from scratch anytime.

## Create the project

Create a new Laravel project:

```bash
laravel new project-name
```

During installation, choose the following options:

| Option | Choice |
|---|---|
| Starter kit | Vue |
| Authentication provider | Laravel |
| Testing framework | Pest |
| Laravel Boost | No |

Then install the front-end dependencies:

```bash
cd project-name
npm install
```

## Run the project

### Standard method

Start the back-end server (routes, API, database):

```bash
php artisan serve
```

In a second terminal, start the front-end server (asset compilation and hot reload):

```bash
npm run dev
```

### Quick method

A single command runs both the back-end and front-end at once:

```bash
composer run dev
```


> **Note:** In production, you don't run `npm run dev`. You compile the assets once with `npm run build`, and only the back-end runs (served by Nginx or Apache).

## Config API key
Generate key on open https://openrouter.ai/

Then i added in `.env` and `.env.example`
```php
OPENROUTER_API_KEY=VotreCélesteCléAPI
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```
and i also added this in `/config/services.php`
```php
'openrouter' => [
    'api_key' => env('OPENROUTER_API_KEY'),
    'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
],
```
## class askservice
### SimpleAskService
in `app/Services/SimpleAskService.php`, i added this part of code:
```php
<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Facades\Http;

/**
 * Service simplifié pour communiquer avec l'API OpenRouter.
 *
 * Exemple pédagogique utilisant le client HTTP de Laravel.
 */
class SimpleAskService
{
    public const DEFAULT_MODEL = 'openai/gpt-5-mini';

    private string $apiKey;
    private string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config('services.openrouter.api_key');
        $this->baseUrl = rtrim(config('services.openrouter.base_url', 'https://openrouter.ai/api/v1'), '/');
    }

    /**
     * Récupère la liste des modèles disponibles.
     *
     * @return array<int, array{
     *     id: string,
     *     name: string,
     *     description: string,
     *     context_length: int,
     *     max_completion_tokens: int,
     *     input_modalities: array<string>,
     *     output_modalities: array<string>,
     *     supported_parameters: array<string>
     * }>
     */
    public function getModels(): array
    {
        return cache()->remember('openrouter.models', now()->addHour(), function (): array {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
            ])->get($this->baseUrl . '/models');

            return collect($response->json('data', []))
                ->sortBy('name')
                ->map(fn (array $model): array => [
                    'id' => $model['id'],
                    'name' => $model['name'],
                    'description' => $model['description'] ?? '',
                    'context_length' => $model['context_length'] ?? 0,
                    'max_completion_tokens' => $model['top_provider']['max_completion_tokens'] ?? 0,
                    'input_modalities' => $model['architecture']['input_modalities'] ?? [],
                    'output_modalities' => $model['architecture']['output_modalities'] ?? [],
                    'supported_parameters' => $model['supported_parameters'] ?? [],
                ])
                ->values()
                ->toArray()
            ;
        });
    }

    /**
     * Envoie un message et retourne la réponse du modèle.
     *
     * @param array<int, array{
     *     role: 'assistant'|'system'|'tool'|'user',
     *     content: array<int, array{
     *         type: 'image_url'|'text',
     *         text?: string,
     *         image_url?: array{url: string, detail?: string}
     *     }>|string
     * }> $messages
     */
    public function sendMessage(array $messages, ?string $model = null, float $temperature = 1.0): string
    {
        $model = $model ?? self::DEFAULT_MODEL;
        $messages = [$this->getSystemPrompt(), ...$messages];

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Content-Type' => 'application/json',
            'HTTP-Referer' => config('app.url'),
            'X-Title' => config('app.name'),
        ])
            ->timeout(120)
            ->post($this->baseUrl . '/chat/completions', [
                'model' => $model,
                'messages' => $messages,
                'temperature' => $temperature,
            ])
        ;

        // Gestion des erreurs
        if ($response->failed()) {
            $error = $response->json('error.message', 'Erreur inconnue');
            throw new \RuntimeException("Erreur API: {$error}");
        }

        return $response->json('choices.0.message.content', '');
    }

    /**
     * Retourne le prompt système.
     *
     * @return array{role: 'system', content: string}
     */
    private function getSystemPrompt(): array
    {
        $user = auth()->user()?->name ?? 'l\'utilisateur';
        $now = now()->locale('fr')->format('l d F Y H:i');

        return [
            'role' => 'system',
            'content' => view('prompts.system', [
                'now' => $now,
                'user' => $user,
            ])->render(),
        ];
    }
}
```
### System Prompt
In the same time i added a system prompt in `resources/views/prompts/system.blade.php`
```php
Tu es un assistant de chat. La date et lheure actuelle est le {{ $now }}.
Tu es actuellement utilisé par {{ $user }}.
```

## Controller AskController
First i added routes in `routes/web.php`
```php
use App\Http\Controllers\AskController;

Route::middleware('auth')->group(function () {
    Route::get('/ask', [AskController::class, 'index'])->name('ask.index');
    Route::post('/ask', [AskController::class, 'ask'])->name('ask.post');
});
```

then the controler in `app/Http/Controllers/AskController.php`:
```php
<?php

namespace App\Http\Controllers;

use App\Services\SimpleAskService;
use Illuminate\Http\Request;
use Inertia\Inertia;

class AskController extends Controller
{
    public function __construct(private SimpleAskService $askService) {}

    public function index()
    {
        return Inertia::render('Ask/Index', [
            'models' => $this->askService->getModels(),
            'selectedModel' => $this->askService::DEFAULT_MODEL,
        ]);
    }

    public function ask(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
            'model' => 'required|string',
        ]);

        $response = null;
        $error = null;
        $messages = [[
            'role' => 'user',
            'content' => $request->message,
        ]];

        try {
            $response = $this->askService->sendMessage(
                messages: $messages,
                model: $request->model
            );
        } catch (\Exception $e) {
            $error = $e->getMessage();
        }

        return Inertia::render('Ask/Index', [
            'models' => $this->askService->getModels(),
            'selectedModel' => $request->model,
            'message' => $request->message,
            'response' => $response,
            'error' => $error,
        ]);
    }
}
```
## front
in `resources/js/pages/Ask/Index.vue`
### Props
```php
<script setup>
import { useForm } from '@inertiajs/vue3'
import { ask } from '@/actions/App/Http/Controllers/AskController'

const props = defineProps({
    models: Array,
    selectedModel: String,
    message: String,
    response: String,
    error: String,
})

const form = useForm({
    message: props.message ?? '',
    model: props.selectedModel,
})

const submit = () => {
    form.post(ask())
}

<template>

    <Head title="Poser une question" />

    <div class="min-h-screen bg-neutral-950 text-neutral-100">
        <div class="mx-auto max-w-3xl space-y-6 px-4 py-10">
            <h1 class="text-2xl font-bold">Poser une question</h1>

            <!-- Formulaire -->
            <div class="space-y-4">
                <!-- Sélecteur de modèle -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Modèle</label>
                    <select v-model="form.model" class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2">
                        <option v-for="model in props.models" :key="model.id" :value="model.id">
                            {{ model }}
                        </option>
                    </select>
                </div>

                <!-- Champ question -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Votre question</label>
                    <textarea v-model="form.message" rows="4"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2"
                        placeholder="Posez votre question..." />
                    <p v-if="form.errors.message" class="mt-1 text-sm text-red-500">
                        {{ form.errors.message }}
                    </p>
                </div>

                <!-- Bouton -->
                <button @click="submit" :disabled="form.processing"
                    class="rounded-md bg-blue-600 px-4 py-2 text-white transition hover:bg-blue-700 disabled:opacity-50">
                    {{ form.processing ? 'Envoi...' : 'Envoyer' }}
                </button>
            </div>

            <!-- Erreur API -->
            <div v-if="props.error" class="rounded-md bg-red-950/30 p-4 text-red-400">
                Erreur : {{ props.error }}
            </div>

            <!-- Réponse -->
            <div v-if="props.response" class="rounded-xl border border-neutral-700 p-4">
                <MarkdownRenderer :content="props.response" />
            </div>
        </div>
    </div>
</template>
```
we also need to install the marksown modulul
```bash
npm install markdown-it highlight.js
```
and create `ressources/js/components/MarkdownRenderer.vue`
