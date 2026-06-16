<?php

namespace App\Http\Controllers;

use App\Services\SimpleAskService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\Conversation;
use App\Services\SimpleAskStreamService;

class AskController extends Controller
{
    public function __construct(private SimpleAskService $askService, private SimpleAskStreamService $streamService)
    {
    }

    public function index()
    {
        return Inertia::render('Ask/Index', [
            'models' => $this->askService->getModels(),
            'selectedModel' => $this->askService::DEFAULT_MODEL,
        ]);
    }

    public function ask(Request $request)
    {
        $response = null;
        $error = null;
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

        $conversation = !empty($validated['conversation_id']) ?
            $request->user()->conversations()->findOrFail($validated['conversation_id']) :
            $request->user()->conversations()->create(["title" => null, "favorite_ia" => $validated['model']]);

        $conversation->messages()->create([
            'role' => "user",
            "content" => $message,
        ]);
        $history = $conversation->messages()->orderBy('created_at')->get();
        $formated_history = $history->map(fn($message) => ['role' => $message->role, 'content' => $message->content])->toArray();
        return response()->stream(
            function () use ($formated_history, $validated, $conversation) {
                $fullResponse = $this->streamService->streamToOutput(
                    messages: $formated_history,
                    model: $validated['model'],
                );

                $conversation->messages()->create([
                    'role' => 'assistant',
                    'content' => $fullResponse,
                ]);

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
