<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\SimpleAskService;
use App\Services\SimpleAskStreamService;
use Illuminate\Http\Request;
use Inertia\Inertia;

class AskController extends Controller
{
    public function __construct(
        private SimpleAskService $askService,
        private SimpleAskStreamService $streamService,
    ) {
    }

    public const TITLE_MODEL = 'google/gemini-2.5-flash-lite';

    /**
     * Return a blank page, with a fresh new chat.
     *
     * @return \Inertia\Response the chat page with no active conversation
     */
    public function index()
    {
        return Inertia::render('Ask/Index', [
            'models' => $this->askService->getModels(),
            'selectedModel' => auth()->user()->favorite_ia ?? $this->askService::DEFAULT_MODEL,
        ]);
    }

    /**
     * Handle an incoming chat message: store it, stream the AI response,
     * generate the title on the first exchange, and raise the insanity level.
     *
     * @param Request $request The HTTP request containing the message, model and optional conversation id
     * @return \Symfony\Component\HttpFoundation\StreamedResponse The streamed AI response
     */
    public function ask(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string',
            'model' => 'required|string',
            'conversation_id' => 'nullable|exists:conversations,id',
        ]);

        $message = $validated['message'];
        foreach ($request->user()->shortcut ?? [] as $shortcut) {
            $trigger = '/' . $shortcut['command'];
            if (str_starts_with($message, $trigger)) {
                $message = $shortcut['instruction'] . substr($message, strlen($trigger));
                break;
            }
        }

        $conversation = !empty($validated['conversation_id'])
            ? $request->user()->conversations()->findOrFail($validated['conversation_id'])
            : $request->user()->conversations()->create([
                'title' => null,
                'favorite_ia' => $validated['model'],
            ]);

        $conversation->messages()->create([
            'role' => 'user',
            'content' => $message,
        ]);

        if ($conversation->title === null) {
            try {
                $title = $this->askService->sendMessage(
                    messages: [['role' => 'user', 'content' => $message]],
                    model: self::TITLE_MODEL,
                    system_prompt_file: 'prompts.generate_title',
                );
            } catch (\Throwable) {
                $title = $this->askService->sendMessage(
                    messages: [['role' => 'user', 'content' => $message]],
                    model: $validated['model'],
                    system_prompt_file: 'prompts.generate_title',
                );
            }
            $conversation->update(['title' => trim($title)]);
        }

        // Construit l'historique pour l'API
        $formated_history = $conversation->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn($m) => ['role' => $m->role, 'content' => $m->content])
            ->toArray();

        return response()->stream(
            function () use ($formated_history, $validated, $conversation) {
                // Continue le traitement même si le client ferme la connexion
                ignore_user_abort(true);

                $fullResponse = $this->streamService->streamToOutput(
                    messages: $formated_history,
                    model: $validated['model'],
                    insanity: $conversation->insanity ?? 0,
                );

                $conversation->messages()->create([
                    'role' => 'assistant',
                    'content' => $fullResponse,
                ]);

                $conversation->increment('insanity');
            },
            headers: [
                'Content-Type' => 'text/plain; charset=utf-8',
                'Cache-Control' => 'no-cache, no-store',
                'X-Accel-Buffering' => 'no',
                'X-Conversation-Id' => $conversation->id,
            ]
        );
    }
}