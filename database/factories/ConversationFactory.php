<?php

namespace Database\Factories;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Conversation>
 */
class ConversationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title' => fake()->sentence(4),
            'favorite_ia' => fake()->randomElement([
                'openai/gpt-4o-mini',
                'google/gemini-2.5-flash-lite',
                'deepseek/deepseek-v4-flash',
                'anthropic/claude-3-haiku',
            ]),
            'insanity' => 0,
        ];
    }

    /** Conversation with no title yet (freshly created). */
    public function untitled(): static
    {
        return $this->state(['title' => null, 'insanity' => 0]);
    }

    /** Force a specific insanity level (for unit tests). */
    public function withInsanity(int $level): static
    {
        return $this->state(['insanity' => $level]);
    }
}