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
    ) {}

    public function index()
    {
        return Inertia::render('Ask/Index', [
            'models' => $this->askService->getModels(),
            'selectedModel' => $this->askService::DEFAULT_MODEL,
        ]);
    }

    public function ask(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string',
            'model' => 'required|string',
            'conversation_id' => 'nullable|exists:conversations,id',
        ]);

        // Remplace un éventuel raccourci (/command) par son instruction
        $message = $validated['message'];
        foreach ($request->user()->shortcut ?? [] as $shortcut) {
            $trigger = '/' . $shortcut['command'];
            if (str_starts_with($message, $trigger)) {
                $message = $shortcut['instruction'] . substr($message, strlen($trigger));
                break;
            }
        }

        // Récupère la conversation existante ou en crée une nouvelle
        $conversation = !empty($validated['conversation_id'])
            ? $request->user()->conversations()->findOrFail($validated['conversation_id'])
            : $request->user()->conversations()->create([
                'title' => null,
                'favorite_ia' => $validated['model'],
            ]);

        // Mémorise le modèle choisi sur l'utilisateur
        $request->user()->update(['favorite_ia' => $validated['model']]);

        // Stocke le message de l'utilisateur
        $conversation->messages()->create([
            'role' => 'user',
            'content' => $message,
        ]);

        // Construit l'historique pour l'API
        $formated_history = $conversation->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn($m) => ['role' => $m->role, 'content' => $m->content])
            ->toArray();

        return response()->stream(
            function () use ($formated_history, $validated, $conversation) {
                // Continue le traitement même si le client ferme la connexion
                // (sinon la génération du titre ci-dessous serait interrompue)
                ignore_user_abort(true);

                // Stream la réponse en direct et récupère le texte complet
                $fullResponse = $this->streamService->streamToOutput(
                    messages: $formated_history,
                    model: $validated['model'],
                );

                // Stocke la réponse de l'assistant
                $conversation->messages()->create([
                    'role' => 'assistant',
                    'content' => $fullResponse,
                ]);

                // Génère le titre au premier échange
                if ($conversation->title === null) {
                    $title = $this->askService->sendMessage(
                        messages: [...$formated_history, ['role' => 'assistant', 'content' => $fullResponse]],
                        model: $validated['model'],
                        system_prompt_file: 'prompts.generate_title',
                    );
                    $conversation->update(['title' => trim($title)]);
                }
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
