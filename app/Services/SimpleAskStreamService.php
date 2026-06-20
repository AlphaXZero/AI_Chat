<?php

declare(strict_types=1);

namespace App\Services;

use Generator;
use Illuminate\Support\Facades\Http;
use Psr\Http\Message\StreamInterface;

/**
 * Streaming OpenRouter service: emits the model's response token by token via SSE.
 *
 * Compatible with Laravel's useStream on the front end. Echoes content directly
 * to the output buffer while accumulating the full text to be stored afterwards.
 */
class SimpleAskStreamService extends BaseAskService
{
    /**
     * Stream a completion in real time to the output and return the full text.
     *
     * @param array<int, array{role: string, content: string}> $messages The conversation history
     * @param string|null $model The model id to use (falls back to DEFAULT_MODEL)
     * @param int $insanity The current insanity level, passed to the system prompt
     * @return string The complete accumulated response, for storage
     */
    public function streamToOutput(
        array $messages,
        ?string $model = null,
        int $insanity = 0,
    ): string {
        $fullContent = '';

        $response = $this->sendStreamRequest($messages, $model, $insanity);

        if ($response->failed()) {
            echo "[ERROR] " . $response->json('error.message', 'HTTP Error');
            $this->flush();
            return $fullContent;
        }

        foreach ($this->parseSSEStream($response->toPsrResponse()->getBody()) as $event) {
            if ($event['type'] === 'error') {
                echo "[ERROR] " . $event['data'];
                $this->flush();
                return $fullContent;
            }

            if ($event['type'] === 'content' && $event['data']) {
                echo $event['data'];
                $fullContent .= $event['data'];
                $this->flush();
            }

            if ($event['type'] === 'reasoning' && $event['data']) {
                echo "[REASONING]" . $event['data'] . "[/REASONING]";
                $this->flush();
            }
        }

        return $fullContent;
    }

    /**
     * Flush the output buffer immediately so tokens reach the client in real time.
     */
    private function flush(): void
    {
        if (ob_get_level() > 0) {
            ob_flush();
        }
        flush();
    }

    /**
     * Send the streaming request to the API.
     *
     * @param array<int, array{role: string, content: string}> $messages The conversation history
     * @param string|null $model The model id to use (falls back to DEFAULT_MODEL)
     * @param int $insanity The current insanity level, passed to the system prompt
     * @return \Illuminate\Http\Client\Response The raw streaming HTTP response
     */
    private function sendStreamRequest(
        array $messages,
        ?string $model,
        int $insanity,
    ): \Illuminate\Http\Client\Response {
        $payload = [
            'model' => $model ?? self::DEFAULT_MODEL,
            'messages' => [$this->getSystemPrompt('prompts.system', $insanity), ...$messages],
            'stream' => true,
        ];

        return Http::withToken($this->apiKey)
            ->withHeaders([
                'HTTP-Referer' => config('app.url'),
                'X-Title' => config('app.name'),
            ])
            ->withOptions(['stream' => true])
            ->timeout(120)
            ->post("{$this->baseUrl}/chat/completions", $payload);
    }

    /**
     * Parse an SSE stream and yield each decoded event.
     *
     * @param StreamInterface $body The raw response body
     * @return Generator<array{type: string, data: string|null}> The decoded events
     */
    private function parseSSEStream(StreamInterface $body): Generator
    {
        $buffer = '';

        while (!$body->eof()) {
            $buffer .= $body->read(1024);

            while (($pos = strpos($buffer, "\n")) !== false) {
                $line = trim(substr($buffer, 0, $pos));
                $buffer = substr($buffer, $pos + 1);

                if ($event = $this->parseSSELine($line)) {
                    yield $event;
                }
            }
        }
    }

    /**
     * Parse a single SSE line into an event.
     *
     * @param string $line The raw SSE line
     * @return array{type: string, data: string|null}|null The event, or null if the line is ignored
     */
    private function parseSSELine(string $line): ?array
    {
        if ($line === '' || str_starts_with($line, ':')) {
            return null;
        }

        if (!str_starts_with($line, 'data: ')) {
            return null;
        }

        $data = substr($line, 6);

        if ($data === '[DONE]') {
            return ['type' => 'done', 'data' => null];
        }

        return $this->parseJSON($data);
    }

    /**
     * Decode the JSON payload of an SSE chunk into an event.
     *
     * @param string $json The JSON string from the chunk
     * @return array{type: string, data: string|null}|null The decoded event, or null if irrelevant
     */
    private function parseJSON(string $json): ?array
    {
        try {
            $parsed = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

            if (isset($parsed['error'])) {
                return ['type' => 'error', 'data' => $parsed['error']['message'] ?? 'Unknown error'];
            }

            $delta = $parsed['choices'][0]['delta'] ?? [];

            if (!empty($delta['content'])) {
                return ['type' => 'content', 'data' => $delta['content']];
            }

            if (!empty($delta['reasoning'])) {
                return ['type' => 'reasoning', 'data' => $delta['reasoning']];
            }

            if (!empty($delta['reasoning_content'])) {
                return ['type' => 'reasoning', 'data' => $delta['reasoning_content']];
            }

            return null;
        } catch (\JsonException) {
            return null;
        }
    }
}