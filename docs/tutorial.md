# Tutorial Laravel + Vue

This tutorial documents how the project is built, so I can rebuild it from scratch anytime.

## Create the project

Create a new Laravel project:

```bash
laravel new project-name
```

During installation, I chose the following options:

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

Generate a key on https://openrouter.ai/

Then I added it in `.env` and `.env.example`:

```php
OPENROUTER_API_KEY=YourApiKeyHere
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

And I also added this in `/config/services.php`:

```php
'openrouter' => [
    'api_key' => env('OPENROUTER_API_KEY'),
    'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
],
```

## SimpleAskService

### SimpleAskService

In `app/Services/SimpleAskService.php`, I added this code:

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

> **Note:** `sendMessage` returns a `string` (the model's reply, extracted from `choices.0.message.content`). It also throws a `RuntimeException` if the API call fails — that's why I wrap the call in a try/catch later.

### System prompt

At the same time I added a system prompt in `resources/views/prompts/system.blade.php`:

```blade
Tu es un assistant de chat. La date et l'heure actuelle est le {{ $now }}.
Tu es actuellement utilisé par {{ $user }}.
```

## AskController

First I added the routes in `routes/web.php`:

```php
use App\Http\Controllers\AskController;

Route::middleware('auth')->group(function () {
    Route::get('/ask', [AskController::class, 'index'])->name('ask.index');
    Route::post('/ask', [AskController::class, 'ask'])->name('ask.post');
});
```

Then the controller in `app/Http/Controllers/AskController.php` (first version, without history):

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

## Front-end

In `resources/js/pages/Ask/Index.vue`:

```vue
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
</script>

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
                            {{ model.name }}
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

> **Note:** In the `<option>` I display `{{ model.name }}` and not `{{ model }}`, because each model is an object (see `getModels()`), not a string. Displaying the whole object would print `[object Object]`.

We also need to install the markdown module:

```bash
npm install markdown-it highlight.js
```

And create `resources/js/components/MarkdownRenderer.vue` (to render markdown and highlight code blocks).

At this point we have a basic chat, but without history.

## Database

We need a database to store and retrieve the conversation history.

### Create model, migration, factory, seeder

See `docs/class_diagram.puml`.

```bash
php artisan make:migration add_favorite_ia_to_users_table --table=users
php artisan make:model Conversation -mfs
php artisan make:model Image -mfs
php artisan make:model Message -mfs
```

> **Note:** the `-mfs` flags create the **m**igration, **f**actory and **s**eeder along with the model in a single command.

### Migrations

Then I fill the migrations in `database/migrations/xxxx`. For example, `add_favorite_ia_to_users_table.php`:

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('favorite_ia')->nullable()->after('password');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('favorite_ia');
    });
}
```

Then run:

```bash
php artisan migrate
```


### Eloquent models

To turn database rows into objects we need models. The relations declared here are what let us write things like `$conversation->messages()`.

For example, in `app/Models/Conversation.php`:

```php
class Conversation extends Model
{
    protected $fillable = ['title', 'favorite_ia', 'user_id'];

    public function messages() {
        return $this->hasMany(Message::class);
    }
    public function user() {
        return $this->belongsTo(User::class);
    }
}
```

> **Important:** every field I pass to `create()` must be listed in `$fillable`, otherwise Eloquent silently ignores it (mass assignment protection). I also added a `conversations()` relation on the `User` model and `favorite_ia` to its `$fillable`.

## Modify the controller to handle history

Before anything, we need to send the `conversation_id` from the Vue within the form:

```vue
const form = useForm({
    message: props.message ?? '',
    model: props.selectedModel,
    conversation_id: props.conversation?.id ?? null,
})
```

The `?? null` handles the "new conversation" case: if there is no active conversation, we send `null`, and the controller will create a new one.

First, we collect the `$request` made by the Vue and we use `validate()` to ensure the incoming data is correct:

```php
public function ask(Request $request)
{
    $validated = $request->validate([
        'message'         => 'required|string',
        'model'           => 'required|string',
        'conversation_id' => 'nullable|exists:conversations,id',
    ]);
}
```

`validate()` does two things: it stops the request and returns the errors to the view if a rule fails, and it returns an array containing only the validated fields. `conversation_id` is `nullable` because a brand-new conversation has no id yet, and `exists:conversations,id` makes sure that, when an id *is* sent, it really exists in the database.

Now that we are sure the request is valid, we check whether the conversation is a new one or an existing one. If it already exists we retrieve it, otherwise we create it:

```php
$conversation = ! empty($validated['conversation_id'])
    ? $request->user()->conversations()->findOrFail($validated['conversation_id'])
    : $request->user()->conversations()->create([
        'title'       => null,
        'favorite_ia' => $validated['model'],
    ]);
```

A few things I learned here:

- I don't pass `'user_id' => $request->user()->id` because it's already handled by the Eloquent relation (`conversations()`). Creating through the relation fills the foreign key automatically.
- I retrieve the conversation through `$request->user()->conversations()->findOrFail(...)` instead of `Conversation::findOrFail(...)`. This searches **only** among the current user's conversations, so a user can't access another user's conversation by guessing an id (it returns a 404 instead). It also avoids writing a manual check.
- `title` is `null` on creation because it will be generated later, after the first reply.

Then we store the message typed by the user in the `messages` table:

```php
$conversation->messages()->create([
    'role'    => 'user',
    'content' => $validated['message'],
]);
```

I store the user message **before** calling the API, for two reasons: if the API crashes the message isn't lost, and it needs to already be in the database so it's included in the history I build next.

After this, I build a `$history` that contains every message of the conversation, then I format it so it can be passed to the service. The API has no memory between calls, so I have to send the whole conversation every time, not just the last message:

```php
$history = $conversation->messages()->orderBy('created_at')->get();

$formated_history = $history
    ->map(fn ($message) => ['role' => $message->role, 'content' => $message->content])
    ->toArray();
```

> **Note:** `->toArray()` matters. `sendMessage(array $messages, ...)` expects a plain array, but `->map()` returns a Collection. Without `->toArray()` the call would fail.

Then I have a try/catch that sends the message through the service `app/Services/SimpleAskService.php`. I wrap it in a try/catch because `sendMessage` throws an exception when the API fails. This way I only store the assistant's reply when the call actually succeeds:

```php
try {
    $response = $this->askService->sendMessage(
        messages: $formated_history,
        model: $validated['model']
    );

    $conversation->messages()->create([
        'role'    => 'assistant',
        'content' => $response,
    ]);
} catch (\Exception $e) {
    $error = $e->getMessage();
}
```

Finally I send the props to the Vue. I return the full list of `messages` (re-fetched from the database, so it includes the assistant reply I just stored) instead of a single `response`, so the view can display the whole conversation:

```php
return Inertia::render('Ask/Index', [
    'models'        => $this->askService->getModels(),
    'selectedModel' => $validated['model'],
    'conversation'  => $conversation,
    'messages'      => $conversation->messages()->orderBy('created_at')->get(),
    'error'         => $error,
]);
```

## modify the vue to work with the new controller
here is the view i modified to suit with the new proprs that are sent by the controller
see `feat: refactor index.vue to see every changements`
```html
<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'

const props = defineProps({
    models: Array,
    selectedModel: String,
    conversation: Object,
    messages: Array,
    error: String,
})

const form = useForm({
    message: "",
    model: props.selectedModel,
    conversation_id: props.conversation?.id ?? null,
})

const submit = () => {
    form.post('/ask', {
        preserveScroll: true,
        onSuccess: () => {
            form.reset('message')
            form.conversation_id = props.conversation?.id ?? null
        },
    })
}
</script>
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
                            {{ model.name }}
                        </option>
                    </select>
                </div>
                <div v-for="message in props.messages" :key="message.id" :class="message.role === 'user'
                    ? 'ml-auto max-w-[80%] rounded-xl bg-blue-600/20 border border-blue-800/40 p-4'
                    : 'mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4'">
                    <MarkdownRenderer :content="message.content" />
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
        </div>
    </div>
</template>
```
## handle reload destory and history conversation
In the `routes/web.php`
we need to add the routes in the middleware('auth')->group because we want the user to be connected.    
but it has to change with the conversationid
```php
    Route::get('/conversations/{conversation}', [ConversationController::class, 'show'])->name('conversations.show');
```

## fill the conversations controller
i added this with the previous route i created
```php
<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\SimpleAskService;
use Inertia\Inertia;

class ConversationController extends Controller
{
    public function show(Conversation $conversation, SimpleAskService $simpleAskService)
    {
        abort_unless($conversation->user_id === auth()->id(), 403);
        return Inertia::render('Ask/Index', [
            'models'        => $simpleAskService->getModels(),
            'selectedModel' => $conversation->favorite_ia,
            'conversation'  => $conversation,
            'messages'      => $conversation->messages()->orderBy('created_at')->get(),
        ]);
    }
}
```

I also edited the AskController in order to redirect to the new route

## conversatoins list
i chose to make a global share to avoid repeating in each controller
in `app/Http/Middleware/HandleInertiaRequests.php`
i added in the share array this : 
```php
            'conversations' => fn() => $request->user()->conversations()->orderBy('updated_at', 'desc')->get(),
```

we can now access in vue it with 
```vue
import { usePage } from '@inertiajs/vue3'

const page = usePage()
// puis tu accèdes à page.props.conversations
```

## Misc

### Change a database table

To create a new migration:

```bash
php artisan make:migration add_favorite_ia_to_users_table --table=users
```

To roll back the last migration:

```bash
php artisan migrate:rollback
```