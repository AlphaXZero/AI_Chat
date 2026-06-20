<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // Main test user (password: "password")
        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
            'shortcut' => [
                ['command' => 'corrige', 'instruction' => 'Corrige l\'orthographe et la syntaxe de ce texte en gardant mes tournures de phrases : '],
                ['command' => 'resume', 'instruction' => 'Résume ce texte en 3 points clés : '],
            ],
        ]);

        $this->call([
            ConversationSeeder::class,
        ]);
    }
}