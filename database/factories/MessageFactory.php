<?php

namespace Database\Factories;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Message>
 */
class MessageFactory extends Factory
{
    public function definition(): array
    {
        return [
            'conversation_id' => Conversation::factory(),
            'role' => fake()->randomElement(['user', 'assistant']),
            'content' => fake()->paragraph(),
        ];
    }

    /** Force the message to come from the user. */
    public function fromUser(): static
    {
        return $this->state(['role' => 'user', 'content' => fake()->sentence() . '?']);
    }

    /** Force the message to come from the assistant. */
    public function fromAssistant(): static
    {
        return $this->state(['role' => 'assistant', 'content' => fake()->paragraphs(2, true)]);
    }
}