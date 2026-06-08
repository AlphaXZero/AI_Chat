<?php

namespace App\Http\Controllers;

use App\Services\SimpleAskService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\Conversation;


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
        $response = null;
        $error = null;
        $validated = $request->validate([
            'message' => 'required|string',
            'model' => 'required|string',
            'conversation_id' => 'nullable|exists:conversations,id',
        ]);

        $conversation = ! empty($validated['conversation_id']) ?
            $request->user()->conversations()->findOrFail($validated['conversation_id'])     :
            $request->user()->conversations()->create(["title" => null, "favorite_ia" => $validated['model']]);

        $conversation->messages()->create([
            'role' => "user",
            "content" => $validated["message"],
        ]);
        $history = $conversation->messages()->orderBy('created_at')->get();
        $formated_history = $history->map(fn($message) => ['role' => $message->role, 'content' => $message->content])->toArray();
        try {
            $response = $this->askService->sendMessage(
                messages: $formated_history,
                model: $validated['model']
            );
            $conversation->messages()->create([
                'role' => "assistant",
                'content' => $response,
            ]);
        } catch (\Exception $e) {
            $error = $e->getMessage();
        }

        return Inertia::render('Ask/Index', [
            'models'        => $this->askService->getModels(),
            'selectedModel' => $validated['model'],
            'conversation'  => $conversation,
            'messages'      => $conversation->messages()->orderBy('created_at')->get(),
            'error'         => $error,
        ]);
    }
}
