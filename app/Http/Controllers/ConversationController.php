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
