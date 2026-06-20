<?php

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ─── /ask ─────────────────────────────────────────────────────────────────────

test('guests are redirected to login when accessing /ask', function () {
    $this->get('/ask')->assertRedirect('/login');
});

test('authenticated users can access /ask', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get('/ask')
        ->assertOk();
});

// ─── Conversation ownership ────────────────────────────────────────────────────

test('authenticated users can view their own conversation', function () {
    $user = User::factory()->create();
    $conversation = Conversation::factory()->for($user)->create();

    $this->actingAs($user)
        ->get("/conversations/{$conversation->id}")
        ->assertOk();
});

test('users cannot view a conversation that belongs to someone else', function () {
    $owner = User::factory()->create();
    $intruder = User::factory()->create();
    $conversation = Conversation::factory()->for($owner)->create();

    $this->actingAs($intruder)
        ->get("/conversations/{$conversation->id}")
        ->assertForbidden();
});

// ─── Conversation deletion ─────────────────────────────────────────────────────

test('users can delete their own conversation', function () {
    $user = User::factory()->create();
    $conversation = Conversation::factory()->for($user)->create();

    $this->actingAs($user)
        ->delete("/conversations/{$conversation->id}")
        ->assertRedirect('/ask');

    $this->assertDatabaseMissing('conversations', ['id' => $conversation->id]);
});

test('users cannot delete a conversation that belongs to someone else', function () {
    $owner = User::factory()->create();
    $intruder = User::factory()->create();
    $conversation = Conversation::factory()->for($owner)->create();

    $this->actingAs($intruder)
        ->delete("/conversations/{$conversation->id}")
        ->assertForbidden();

    $this->assertDatabaseHas('conversations', ['id' => $conversation->id]);
});

test('deleting a conversation also deletes its messages', function () {
    $user = User::factory()->create();
    $conversation = Conversation::factory()->for($user)->create();
    Message::factory()->for($conversation)->fromUser()->create();
    Message::factory()->for($conversation)->fromAssistant()->create();

    $this->actingAs($user)
        ->delete("/conversations/{$conversation->id}");

    $this->assertDatabaseMissing('messages', ['conversation_id' => $conversation->id]);
});

// ─── Settings ─────────────────────────────────────────────────────────────────

test('guests cannot update ai settings', function () {
    $this->patch('/settings/ai')->assertRedirect('/login');
});

test('authenticated users can update their ai settings', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->patch('/settings/ai', [
            'profile' => [
                'emojis' => 'peu',
                'tone' => 'formel',
                'length' => 'concis',
            ],
            'shortcuts' => [],
            'favorite_ia' => 'openai/gpt-4o-mini',
        ])
        ->assertRedirect();

    $this->assertDatabaseHas('ai_settings', [
        'user_id' => $user->id,
        'setting' => 'tone',
        'value' => 'formel',
    ]);
});
