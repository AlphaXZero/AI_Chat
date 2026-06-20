# Tutorial: Building a ChatGPT-like app with Laravel + Vue + Inertia

This tutorial documents how I built the project, step by step, so I can rebuild it from scratch anytime. It covers a multi-conversation chat: listing conversations, picking a model, storing history, auto-generating titles, a loading indicator, and markdown rendering.

---

## 1. Create the project

Create a new Laravel project:

```bash
laravel new project-name
```

During installation, I chose:

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

---

## 2. Run the project

### Standard method

Back-end server (routes, API, database):

```bash
php artisan serve
```

In a second terminal, the front-end server (asset compilation + hot reload):

```bash
npm run dev
```

### Quick method

A single command runs both at once:

```bash
composer run dev
```

> **Note:** In production you don't run `npm run dev`. You compile the assets once with `npm run build`, and only the back-end runs (served by Nginx or Apache).

---

## 3. Configure the API key

Generate a key on https://openrouter.ai/

Add it to `.env` and `.env.example`:

```
OPENROUTER_API_KEY=YourApiKeyHere
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

Then register it in `config/services.php`:

```php
'openrouter' => [
    'api_key' => env('OPENROUTER_API_KEY'),
    'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
],
```

> **Why `config/services.php` and not read `env()` directly?** In Laravel you should read env values through `config()`, never `env()` outside config files — config gets cached in production (`php artisan config:cache`) and `env()` returns `null` once that happens.

---

## 4. The SimpleAskService

This service is the only place that talks to OpenRouter. Keeping the HTTP logic here keeps the controllers clean.

In `app/Services/SimpleAskService.php`:

```php
<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Facades\Http;

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

    /** Fetch the list of available models. */
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
                ->toArray();
        });
    }

    /**
     * Send a list of messages and return the model's reply.
     * The $system_prompt_file parameter lets me swap the system prompt
     * (I use a different one to generate conversation titles).
     */
    public function sendMessage(
        array $messages,
        ?string $model = null,
        string $system_prompt_file = 'prompts.system',
        float $temperature = 1.0
    ): string {
        $model = $model ?? self::DEFAULT_MODEL;
        $messages = [$this->getSystemPrompt($system_prompt_file), ...$messages];

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
            ]);

        if ($response->failed()) {
            $error = $response->json('error.message', 'Erreur inconnue');
            throw new \RuntimeException("Erreur API: {$error}");
        }

        return $response->json('choices.0.message.content', '');
    }

    /** Build the system prompt from a Blade view. */
    private function getSystemPrompt(string $system_prompt_file): array
    {
        $user = auth()->user()?->name ?? 'l\'utilisateur';
        $now = now()->locale('fr')->format('l d F Y H:i');

        return [
            'role' => 'system',
            'content' => view($system_prompt_file, [
                'now' => $now,
                'user' => $user,
            ])->render(),
        ];
    }
}
```

> **Two things to remember about `sendMessage`:**
> - It returns a `string` (the reply, extracted from `choices.0.message.content`). So in the controller I get plain text, nothing to unwrap.
> - It throws a `RuntimeException` if the API call fails. That's why I wrap every call in a try/catch later.

### System prompt

In `resources/views/prompts/system.blade.php`:

```blade
Tu es un assistant de chat. La date et l'heure actuelle est le {{ $now }}.
Tu es actuellement utilisé par {{ $user }}.
```

I later added a second prompt `resources/views/prompts/generate_title.blade.php`, used only to generate titles (see section 9).

---

## 5. First version of the controller (no history yet)

Routes in `routes/web.php`:

```php
use App\Http\Controllers\AskController;

Route::middleware('auth')->group(function () {
    Route::get('/ask', [AskController::class, 'index'])->name('ask.index');
    Route::post('/ask', [AskController::class, 'ask'])->name('ask.post');
});
```

The controller — a single question, a single answer, nothing stored:

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

---

## 6. First version of the front-end

In `resources/js/pages/Ask/Index.vue`:

```vue
<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'

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
    form.post('/ask')
}
</script>

<template>
    <Head title="Poser une question" />
    <!-- model selector, textarea, button, single response -->
</template>
```

> **Note:** in the model `<option>` I display `{{ model.name }}`, not `{{ model }}`. Each model is an object (see `getModels()`), so printing the whole object would show `[object Object]`.

Install the markdown renderer:

```bash
npm install markdown-it highlight.js
```

And create `resources/js/components/MarkdownRenderer.vue` to render markdown and highlight code blocks.

At this point I have a basic chat — but with no history. Everything is lost on reload.

---

## 7. The database

I need a database to store and retrieve conversation history.

### Create models, migrations, factories, seeders

See `docs/class_diagram.puml` for the data model.

```bash
php artisan make:migration add_favorite_ia_to_users_table --table=users
php artisan make:model Conversation -mfs
php artisan make:model Image -mfs
php artisan make:model Message -mfs
```

> **Note:** the `-mfs` flags create the **m**igration, **f**actory and **s**eeder alongside the model in one command.

### Fill the migrations

Example, `add_favorite_ia_to_users_table.php`:

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
`$table->timestamp()` is mandatory in order to make the eloquent model work properly

For the `messages` migration, I make the foreign key cascade on delete, so deleting a conversation also deletes its messages (no orphan rows):

```php
$table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
```

Then run:

```bash
php artisan migrate
```

### Eloquent models and relations

Models turn database rows into objects. The relations are what let me write `$conversation->messages()`.

`app/Models/Conversation.php`:

```php
class Conversation extends Model
{
    protected $fillable = ['title', 'favorite_ia', 'user_id'];

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

> **Important:** every field I pass to `create()` must be listed in `$fillable`, otherwise Eloquent silently ignores it (mass-assignment protection). I also added a `conversations()` relation on the `User` model, and `favorite_ia` to its `$fillable`.

The relations go both ways: a `User` *has many* `Conversation`, a `Conversation` *belongs to* a `User` and *has many* `Message`, a `Message` *belongs to* a `Conversation`. Declaring both sides lets me navigate in either direction.

---

## 8. Rework the controller to handle history

### Send the conversation id from Vue

```js
const form = useForm({
    message: '',
    model: props.selectedModel,
    conversation_id: props.conversation?.id ?? null,
})
```

The `?? null` handles the "new conversation" case: if there's no active conversation, I send `null`, and the controller creates a fresh one.

### Validate the request

```php
$validated = $request->validate([
    'message'         => 'required|string',
    'model'           => 'required|string',
    'conversation_id' => 'nullable|exists:conversations,id',
]);
```

`validate()` does two things: it stops the request and returns errors to the view if a rule fails, and it returns an array of only the validated fields. `conversation_id` is `nullable` because a brand-new conversation has no id yet; `exists:conversations,id` makes sure that, when an id *is* sent, it really exists.

### Retrieve or create the conversation

```php
$conversation = ! empty($validated['conversation_id'])
    ? $request->user()->conversations()->findOrFail($validated['conversation_id'])
    : $request->user()->conversations()->create([
        'title'       => null,
        'favorite_ia' => $validated['model'],
    ]);
```

What I learned here:

- I don't pass `'user_id' => ...`. Creating through the relation (`conversations()`) fills the foreign key automatically.
- I retrieve through `$request->user()->conversations()->findOrFail(...)` instead of `Conversation::findOrFail(...)`. This searches **only** the current user's conversations, so nobody can open someone else's conversation by guessing an id — it returns a 404 instead. No manual ownership check needed.
- `title` is `null` on creation because it's generated later (section 9).

### Store the user message

```php
$conversation->messages()->create([
    'role'    => 'user',
    'content' => $validated['message'],
]);
```

I store the user message **before** calling the API: if the API crashes the message isn't lost, and it needs to be in the database so it's included in the history I build next.

### Build the history and call the API

The API has no memory between calls, so I send the whole conversation every time, not just the last message:

```php
$history = $conversation->messages()->orderBy('created_at')->get();

$formated_history = $history
    ->map(fn ($message) => ['role' => $message->role, 'content' => $message->content])
    ->toArray();
```

> **Note:** `->toArray()` matters. `sendMessage(array $messages, ...)` expects a plain array, but `->map()` returns a Collection. Without `->toArray()`, the call fails.

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

I wrap it in a try/catch because `sendMessage` throws on API failure. The assistant reply is created **inside** the `try`, so it's only stored when the call actually succeeds.

---

## 9. Auto-generate a title (after the first reply)

I want a short title generated **once**, on the first exchange. I detect "first exchange" by checking the conversation has no title yet:

```php
if ($conversation->title === null) {
    $conv_title = $this->askService->sendMessage(
        messages: $formated_history,
        model: $validated['model'],
        system_prompt_file: 'prompts.generate_title',
    );
    $conversation->update(['title' => trim($conv_title)]);
}
```

Key points:

- I use an `if`, not a ternary, because I'm triggering an **action** (the `update`) only when the title is null — not just choosing a value. With an `if`, an already-titled conversation makes neither an API call nor a database write.
- `system_prompt_file: 'prompts.generate_title'` swaps the system prompt for one that asks for a short title (that's the extra parameter I added to `sendMessage`).
- `trim()` removes the whitespace/newlines models sometimes add around the title.

This block goes inside the `try`, right after the assistant message is stored.

---

## 10. Handle reload: redirect instead of render

**The problem:** so far, `ask` ended with `Inertia::render(...)`, which keeps the URL on `/ask`. On reload, the browser re-requests `/ask`, which knows about no conversation — so everything is lost.

**The fix** is the Post/Redirect/Get pattern: the POST action redirects to a GET route that carries the conversation id in the URL.

### New route (with a parameter)

In `routes/web.php`, inside the `auth` group (the user must be logged in):

```php
use App\Http\Controllers\ConversationController;

Route::get('/conversations/{conversation}', [ConversationController::class, 'show'])
    ->name('conversations.show');
```

I named the parameter `{conversation}` (matching the model name) so Laravel's **route model binding** resolves it to a `Conversation` object automatically.

### The ConversationController

```php
<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\SimpleAskService;
use Illuminate\Http\Request;
use Inertia\Inertia;

class ConversationController extends Controller
{
    public function show(Request $request, Conversation $conversation, SimpleAskService $askService)
    {
        abort_unless($conversation->user_id === $request->user()->id, 403);

        return Inertia::render('Ask/Index', [
            'models'        => $askService->getModels(),
            'selectedModel' => $conversation->favorite_ia,
            'conversation'  => $conversation,
            'messages'      => $conversation->messages()->orderBy('created_at')->get(),
        ]);
    }
}
```

Notes:

- Route model binding loads the conversation from the URL id, but it does **not** check ownership. So I add `abort_unless(...)` to return 403 if the conversation isn't mine. (A Policy would be cleaner, but this is enough for now.)
- `selectedModel` comes from `$conversation->favorite_ia` here — reopening an old conversation preselects the model it was using.
- I inject `SimpleAskService` as a method parameter (this controller has no constructor injection).

### Make `ask` redirect

The last line of `AskController@ask` becomes:

```php
return redirect()->route('conversations.show', $conversation->id);
```

Now sending a message lands on `/conversations/{id}`. On reload, `show` runs again and reloads everything from the database. Bonus: the display logic now lives only in `show`, so no duplicated `return`.

> **Render vs redirect:** `Inertia::render()` picks *what to display* but leaves the URL unchanged. `redirect()->route()` changes the URL and triggers a new GET request. The reload problem is fixed by redirecting, because reloading a GET page is safe and re-fetches the data.

---

## 11. List the conversations (sidebar)

I want the conversation list available on every chat page. Instead of passing it from each controller, I share it **globally** through the Inertia middleware.

In `app/Http/Middleware/HandleInertiaRequests.php`, inside the `share()` array:

```php
'conversations' => fn () => $request->user()
    ? $request->user()->conversations()->orderBy('updated_at', 'desc')->get()
    : [],
```

Things to note here:

- I guard against a missing user (`$request->user() ? ... : []`). `share()` runs on **every** page, including login/home where nobody is authenticated — calling `->conversations()` on `null` would crash.
- I wrap the value in a closure (`fn () => ...`) so the query only runs when the page actually needs it (an Inertia optimization).
- Sorting by `updated_at desc` puts the freshest conversation on top (newest first).

Globally shared data does **not** arrive in `defineProps`. I read it via `usePage()`:

```js
import { usePage, Link } from '@inertiajs/vue3'
const page = usePage()
// page.props.conversations
```

The sidebar itself:

```html
<Link v-for="conv in page.props.conversations" :key="conv.id"
      :href="`/conversations/${conv.id}`">
    {{ conv.title ?? 'Nouvelle conversation' }}
</Link>
```

What I learned building this:

- **`<Link>` vs `<a>`:** `<Link>` (from Inertia) navigates without a full page reload. It fetches only the new page's data (JSON props), keeps the Vue app alive, and updates the URL. A plain `<a>` would reload all the HTML/JS/CSS and restart the whole app — much slower. `<Link>` is only for internal navigation; external links still use `<a>`.
- **`:href` (with the colon) vs `href`:** the colon tells Vue to evaluate the value as JavaScript. Without it, the URL would be the literal text `` `/conversations/${conv.id}` ``. The backticks make it a template literal so `${conv.id}` is interpolated.
- **`:key="conv.id"`:** the key must be unique and stable per item. Vue uses it to track which DOM element matches which list item when the list changes (add/remove/reorder). Without a stable key, Vue guesses by position, which is slow and causes visual bugs. The conversation's `id` is perfect — unique and never changing. Use `conv.id` (the loop variable), not a global like `page.props.conversations.id`.
- **`?? 'Nouvelle conversation'`** handles conversations whose title hasn't been generated yet.

I wrapped the sidebar and the chat in a horizontal flex container so the sidebar sits on the left and the chat fills the rest:

```html
<div class="flex min-h-screen ...">
    <aside class="w-64 ...">  <!-- sidebar --> </aside>
    <main class="flex-1 ...">  <!-- chat --> </main>
</div>
```

> **Gotcha I hit:** a `flex` container only affects its **direct children**. If you self-close it (`<div class="flex ..."></div>`), the sidebar and chat end up *after* it, not inside it, and nothing lays out side by side. Both columns must be nested inside the flex div.

I sorted the list conversation by their last activity when i enter something in a conversation, tthe conversation itself is not modified, only the message to update the conversation when a message is entered, i had to modify the Message model to touches the conversation when a message is created.
```php
class Message extends Model
{
    ...
    protected $touches = ['conversation'];
```

---

## 12. Loading indicator

`useForm` exposes `form.processing`, which Inertia flips to `true` during the request and back to `false` when it finishes. I already use it on the button (`Envoi...`). I reuse it to show a "typing" bubble after the message list:

```html
<div v-if="form.processing"
     class="mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4">
    <span class="flex gap-1.5">
        <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500"></span>
        <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500" style="animation-delay: 0.15s"></span>
        <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500" style="animation-delay: 0.3s"></span>
    </span>
</div>
```

The `animation-delay` on each dot creates a wave effect. I place it after the messages loop, since that's where the reply will appear.

---

## 13. preference settings
first i made some migrations to add command to user and a table with settings
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->json('shortcut')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('shortcut');
        });
    }
};
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ai_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('setting');
            $table->string('value')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_settings');
    }
};

```
then i let claude make the viewin /ressources/pages/Ask/AiSettingsModal.vue
and i added this in Index.vue
```php
import { ref } from 'vue'
import AiSettingsModal from '@/pages/Ask/AiSettingsModal.vue'
    <button @click="showSettings = true"
        class="mt-auto rounded-lg px-3 py-2 text-left text-sm text-neutral-300 transition hover:bg-neutral-800">
        ⚙️ Instructions personnalisées
    </button>
    <AiSettingsModal :open="showSettings" @close="showSettings = false" />
```
 Now that we have the db and the view(normally i do it after), we can do the model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiSetting extends Model
{
    protected $fillable = ['setting', 'value', 'user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```
and we update the  app/Models/User.php
we add `command` in the fillable and a hasmany for ai_settings


### aisettings controller
we create
```bash
php artisan make:controller AiSettignsController
```

we add the route in routes/web.php
see in misc to know how route works
Now that we send the array to the controller with form.patch(/settings/ai)

we validate the request received:
```php
    public function update(Request $request)
    {
        dd($request->all());
        $validated = $request->validate([
            'profile'                 => 'array',
            'shortcuts'               => 'array',
            'shortcuts.*.command'     => 'nullable|string',
            'shortcuts.*.instruction' => 'nullable|string',
        ]);
    }
```
`shortcuts.*.command` take every command
to update the user table with command:
```php
$request->user()->update(['shortcut' => $request['shortcuts']]);
```
for the settings its more complicated, we need to iterate in the array put the key in table with its value if the value is not the same
```php
        foreach ($validated['profile'] as $setting => $value) {
            $request->user()->aiSettings()->updateOrCreate(
                ['setting' => $setting],
                ['value' => $value]
            );
        }
        return back();
```
the `return back()` send the user back to the page he was before opening the settings ai


Now that the controlers send the infos entered in the db, it would be cool if when we open the settings it fill it whit the data we have in db
so i added them in the /Http/HandleInertiaRequest in the share to share within every page in the app
```php
'aiProfile' => fn () => $request->user()
    ? $request->user()->aiSettings->pluck('value', 'setting')
    : (object) [],
'shortcuts' => fn () => $request->user()?->shortcut ?? [],
```
to retrieve them in Aisettings modal we need to send them from index when we open the modal
```html
    <AiSettingsModal :open="showSettings" :profile="page.props.aiProfile" :shortcuts="page.props.shortcuts"
        @close="showSettings = false" />
```
### how to use settings in prompts system
we have already a system prompt in simpleaskservice so we need to update it to use our settings

```php
    private function getSystemPrompt(string $system_prompt_file): array
    {
        $user = auth()->user()?->name ?? 'l\'utilisateur';
        $now = now()->locale('fr')->format('l d F Y H:i');
        $profile = $user?->aiSettings->pluck('value', 'setting') ?? collect();
        return [
            'role' => 'system',
            'content' => view($system_prompt_file, [
                'now' => $now,
                'user' => $user,
                'profile' => $profile,
            ])->render(),
        ];
    }
```

we can now use them in systemprompt

```blade
Tu es un assistant de chat. La date et lheure actuelle est le {{ $now }}.
Tu es actuellement utilisé par {{ $user }}.
@if (($profile['emojis'] ?? null) === 'beaucoup')
    Utilise beaucoup d'émojis dans tes réponses.
@elseif(($profile['emojis'] ?? null) === 'peu')
    Utilise quelques émojis, avec parcimonie.
@elseif(($profile['emojis'] ?? null) === 'non')
    N'utilise aucun émoji.
@endif
Prends un ton {{ $profile['tone'] ?? 'neutre' }}
@if (($profile['length'] ?? null) === 'normal')
    réponds avec une longueur normale
@elseif(($profile['length'] ?? null) === 'detaille')
    repond avec beaucup de details
@elseif(($profile['length'] ?? null) === 'concis')
    sois le plus concis possible
@endif

```

### coammand
its harder we need to update the controler and check the user input to see if there is a '/' folllowed by a command in the db

i added this in the controller, which detect if a / is in the user message and replace it with the instructions
```php
        $message = $validated['message'];
        foreach ($request->user()->shortcut ?? [] as $shortcut) {
            $trigger = '/' . $shortcut['command'];
            if (str_starts_with($message, $trigger)) {
                $message = $shortcut['instruction'] . substr($message, strlen($trigger));
                break;
            }
        }
```

## Streaming
it was very boring, check the git, i mainly used claude to achieve making working it \(:

## Completing the do-list
now that the main project is working properly i will do a lot of qol ideas i added in my README.md

### navbar
actually i have the default starter kit navbar.
The default navbar is in `ressources/js/app.ts`
```php
layout: (name) => {
    switch (true) {
        case name === 'Welcome':           return null;        // pas de layout
        case name.startsWith('auth/'):     return AuthLayout;
        case name.startsWith('settings/'): return [AppLayout, SettingsLayout];
        default:                           return AppLayout;    // ← TES pages tombent ici
    }
}
```
we need to change the default since our pagename is ask.index it wont fit anything 

then i used claude to make the navbar
```html
        <aside class="flex w-64 flex-col border-r border-neutral-800 bg-neutral-900">
            <!-- Haut : titre / branding (fixe) -->
            <div class="shrink-0 border-b border-neutral-800 p-4">
                <h2 class="text-lg font-bold">💬 Mon Chat</h2>
            </div>

            <!-- Milieu : liste des conversations (scrolle) -->
            <div class="min-h-0 flex-1 overflow-y-auto p-3">
                <Link href="/ask"
                    class="mb-2 block rounded-lg bg-blue-600 px-3 py-2 text-center text-sm font-medium text-white transition hover:bg-blue-700">
                    + Nouvelle conversation
                </Link>

                <div v-for="conv in page.props.conversations" :key="conv.id"
                    class="group flex items-center rounded-lg text-sm text-neutral-300 transition hover:bg-neutral-800"
                    :class="{ 'bg-neutral-800 text-white': conv.id === props.conversation?.id }">

                    <Link :href="`/conversations/${conv.id}`" class="flex-1 truncate px-3 py-2">
                        {{ conv.title ?? "Nouvelle conversation" }}
                    </Link>

                    <button @click="deleteConversation(conv.id)"
                        class="mr-2 hidden text-neutral-500 hover:text-red-400 group-hover:block">
                        ✕
                    </button>
                </div>
            </div>

            <!-- Bas : réglages + déconnexion (fixe) -->
            <div class="shrink-0 flex flex-col gap-1 border-t border-neutral-800 p-3">
                <button @click="showSettings = true"
                    class="rounded-lg px-3 py-2 text-left text-sm text-neutral-300 transition hover:bg-neutral-800">
                    ⚙️ Instructions personnalisées
                </button>
                <button @click="logout"
                    class="rounded-lg px-3 py-2 text-left text-sm text-neutral-400 transition hover:bg-neutral-800 hover:text-red-400">
                    Déconnexion
                </button>
            </div>
        </aside>

```

### button delete conversation

i added a delete route:
```php
    Route::delete('/conversations/{conversation}', [ConversationController::class, 'destroy'])->name('conversations.destroy');
```
and changed the conversation controller
```php
    public function destroy(Conversation $conversation)
    {
        abort_unless($conversation->user_id === auth()->id(), 403);

        $conversation->delete();

        return redirect('/ask');
    }
```

For the view i added in the script
```php
const deleteConversation = (id) => {
    return router.delete(`/conversations/${id}`)
}
```

and changed the "navbar" with converstions
```html
                <div v-for="conv in page.props.conversations" :key="conv.id"
                    class="group flex items-center rounded-lg text-sm text-neutral-300 transition hover:bg-neutral-800"
                    :class="{ 'bg-neutral-800 text-white': conv.id === props.conversation?.id }">

                    <Link :href="`/conversations/${conv.id}`" class="flex-1 truncate px-3 py-2">
                        {{ conv.title ?? "Nouvelle conversation" }}
                    </Link>

                    <button @click="deleteConversation(conv.id)"
                        class="mr-2 hidden text-neutral-500 hover:text-red-400 group-hover:block">
                        ✕
                    </button>
                </div>
```
i changed the link v-for conv into conv in order to separate the link for show and delete

### adding insanity var

we need an insanity entry in the conversation table so we launch a migration
```php
php artisan make:migration add_insanity_to_conversation_table
```
we implement the migration
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->integer("insanity")->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->dropColumn("insanity");
        });
    }
};

```
run the migration
```php
php artisan migrate
```

i wanted to add the a var in the controller but i found a laravel functioin that increment directly the db

```php
                if ($conversation->insanity < 5) {
                    $conversation->increment("insanity");
                }
```

to retrieve the insanity level in the view i did that, because i already share the conversation variable
```php
const insanity = computed(() => props.conversation?.insanity ?? 0)
```

### redirect on ask, when logging in
we juste need to modify thies line in `config/fortify.php`
```php
    'home' => '/dashboard',
```

### changing ui by insanity level   
in the script i added those vlaue
```php
const aOpacity = computed(() => {
    if (insanity.value >= 5) return 1
    return insanity.value * 0.06
})

const titleColor = computed(() => {
    const i = insanity.value
    if (i <= 0) return '#d4af37'
    if (i === 1) return '#dc9730'
    if (i === 2) return '#e37e2a'
    if (i === 3) return '#e96323'
    if (i === 4) return '#f0451c'
    if (i === 5) return '#f72612'
    return '#ff0000'
})
```
with that in the template
```php
    <h1 class="text-base font-bold tracking-[0.25em]" :style="{ color: titleColor }">
        CHAT <span :style="{ opacity: aOpacity }">A</span>NORMAL
    </h1>
```

I choose to do a red gradient arround the page
i added this at the bottom
```php
<style>
@keyframes pulse-ambiance {

    0%,
    100% {
        opacity: 0.55;
    }

    50% {
        opacity: 1;
    }
}

.bg-normal {
    background: #0a0a0a;
}

.reality-broken {
    background-color: #000;
    background-image:
        linear-gradient(45deg, #3d0a52 25%, transparent 25%, transparent 75%, #3d0a52 75%),
        linear-gradient(45deg, #3d0a52 25%, transparent 25%, transparent 75%, #3d0a52 75%);
    background-size: 40px 40px;
    background-position: 0 0, 20px 20px;
}
</style>
```
we can also see the @keyframe pulse-ambiance that add like a hearth beat arround the ui

### favorite_ia in settings
we already load the models in the index.vue so we need to give them in the setting modal props, :favorite_ia="model" and favorite_ia to know which one is currently selected
```html
        <AiSettingsModal :open="showSettings" :profile="page.props.aiProfile" :shortcuts="page.props.shortcuts"
            :models="props.models" :favorite_ia="model" @close="showSettings = false" />
    </div>
```
now we had them in the props of aisettingsmodals.vue
```vue
const props = defineProps({
    open: Boolean,
    profile: { type: Object, default: () => ({}) },
    shortcuts: { type: Array, default: () => [] },
    models: { type: Array, default: () => [] },
    favorite_ia: { type: String, default: "" }
})
```
we need to add favorite_ia in useForm as its only readonly when in props
```
const form = useForm({
    favorite_ia: props.favorite_ia,
    profile: {
        emojis: props.profile.emojis ?? 'non',
        tone: props.profile.tone ?? 'neutre',
        length: props.profile.length ?? 'normal',
    },
    shortcuts: [...props.shortcuts],
})
```
we add the select now
```html
            <!-- ─── Favorite ia ──────── -->
            <section class="mt-6 space-y-3">
                <h3 class="text-xs font-medium uppercase tracking-wider text-slate-500">Modèle d'ia favorite</h3>

                <div>
                    <label class="mb-1.5 block text-sm text-slate-300">Modèle par défaut</label>
                    <select v-model="form.favorite_ia"
                        class="w-full rounded-lg px-3 py-2 text-sm text-slate-200 outline-none transition"
                        style="background: #161616; border: 1px solid #2a2a2a">
                        <option v-for="m in props.models" :key="m.id" :value="m.id">
                            {{ m.name }}
                        </option>
                    </select>
                </div>
            </section>
```




## Misc

### IMPORTANT how the mvc work
here i want to save the settings chosen by the user in the db

the view send a http request when i do `form.patch('/settings/ai')` because in routes/web.php i added `Route::patch('/settings/ai', [AiSettingsController::class, 'update'])->name('settings.ai.update');`, this route says when this request (when the page /settings/ai send patch) occurs, call update from AiSettingsController; then the function in the controller works now and the method can save in db or resend http request with inertia:render 

### Create a new migration

```bash
php artisan make:migration add_favorite_ia_to_users_table --table=users
```

### Make fresh migration 
```bash
php artisan migrate:fresh
```

### Seed db
```bash
php artisan db:seed
```

### Roll back the last migration

```bash
php artisan migrate:rollback
```

### Voir les routes
```php
php artisan route:list
```
x---
