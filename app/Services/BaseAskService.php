<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

/**
 * Base class shared by the blocking and streaming OpenRouter services.
 *
 * Holds the API credentials and the logic common to both children:
 * fetching the available models and building the system prompt.
 */
abstract class BaseAskService
{
    public const DEFAULT_MODEL = 'deepseek/deepseek-v4-flash';

    protected string $apiKey;
    protected string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config('services.openrouter.api_key');
        $this->baseUrl = rtrim(config('services.openrouter.base_url', 'https://openrouter.ai/api/v1'), '/');
    }

    /**
     * Fetch the list of available models from OpenRouter (cached for one hour).
     *
     * @return array<int, array{
     *     id: string,
     *     name: string,
     *     description: string,
     *     context_length: int,
     *     max_completion_tokens: int,
     *     input_modalities: array<int, string>,
     *     output_modalities: array<int, string>,
     *     supported_parameters: array<int, string>
     * }> The list of models, sorted by name
     */
    public function getModels(): array
    {
        return cache()->remember('openrouter.models', now()->addHour(), function (): array {
            $response = Http::withToken($this->apiKey)->get("{$this->baseUrl}/models");

            return collect($response->json('data', []))
                ->sortBy('name')
                ->map(fn(array $model): array => [
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
     * Build the system prompt message from a Blade view.
     *
     * @param string $system_prompt_file The Blade view used as the system prompt
     * @param int $insanity The current insanity level, injected into the prompt
     * @return array{role: 'system', content: string} The system message ready for the API
     */
    protected function getSystemPrompt(string $system_prompt_file = 'prompts.system', int $insanity = 0): array
    {
        $user = auth()->user();
        $profile = $user?->aiSettings->pluck('value', 'setting') ?? collect();

        return [
            'role' => 'system',
            'content' => view($system_prompt_file, [
                'now' => now()->locale('fr')->format('l d F Y H:i'),
                'user' => $user?->name ?? 'l\'utilisateur',
                'profile' => $profile,
                'insanity' => $insanity,
            ])->render(),
        ];
    }
}