<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Facades\Http;

/**
 * Blocking OpenRouter service: sends a request and returns the full response at once.
 *
 * Used for short, non-streamed completions such as generating a conversation title.
 */
class SimpleAskService extends BaseAskService
{
    /**
     * Send a message to the model and return its full response.
     *
     * @param array<int, array{role: string, content: string}> $messages The conversation history
     * @param string|null $model The model id to use (falls back to DEFAULT_MODEL)
     * @param string $system_prompt_file The Blade view used as the system prompt
     * @return string The model's response content
     *
     * @throws \RuntimeException If the API call fails
     */
    public function sendMessage(array $messages, ?string $model = null, string $system_prompt_file = "prompts.system"): string
    {
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
            ]);

        if ($response->failed()) {
            $error = $response->json('error.message', 'Erreur inconnue');
            throw new \RuntimeException("Erreur API: {$error}");
        }

        return $response->json('choices.0.message.content', '');
    }
}