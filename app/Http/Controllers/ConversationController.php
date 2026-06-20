<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\SimpleAskService;
use Inertia\Inertia;

class ConversationController extends Controller
{
    /**
     * Display a conversation with its messages
     *
     * @param Conversation $conversation The conversation to display (route-model binding)
     * @param SimpleAskService $simpleAskService Service used to fetch the available models
     * @return \Inertia\Response The chat page rendered with the conversation and its messages
     */
    public function show(Conversation $conversation, SimpleAskService $simpleAskService)
    {
        abort_unless($conversation->user_id === auth()->id(), 403);
        return Inertia::render('Ask/Index', [
            'models' => $simpleAskService->getModels(),
            'selectedModel' => $conversation->favorite_ia,
            'conversation' => $conversation,
            'messages' => $conversation->messages()->orderBy('created_at')->get(),

        ]);
    }

    /**
     * Delete a conversation and its messages (deleted on cascade).
     *
     * @param Conversation $conversation The conversation to delete
     * @return \Illuminate\Http\RedirectResponse Redirects to a new chat to avoid a "not found" error
     */
    public function destroy(Conversation $conversation)
    {
        abort_unless($conversation->user_id === auth()->id(), 403);

        $conversation->delete();

        return redirect('/ask');
    }
}
