<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ConversationSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $user = User::where('email', 'test@example.com')->first();

        if (!$user) {
            return;
        }

        // A normal conversation (2 exchanges → insanity 2)
        $conv1 = Conversation::factory()->for($user)->create([
            'title' => 'Recette de pizza maison',
        ]);
        Message::factory()->for($conv1)->fromUser()->create(['content' => 'Comment faire une pizza maison ?']);
        Message::factory()->for($conv1)->fromAssistant()->create(['content' => 'Pour une pizza maison, il vous faut de la farine, de la levure, de l\'eau tiède, du sel, de la sauce tomate et vos garnitures préférées. Pétrissez la pâte pendant 10 minutes, laissez-la reposer 1h, puis étalez-la et enfournez à 250°C pendant 12 minutes.']);
        Message::factory()->for($conv1)->fromUser()->create(['content' => 'Quelle est la meilleure garniture ?']);
        Message::factory()->for($conv1)->fromAssistant()->create(['content' => 'La mozzarella et le basilic frais restent indétrônables… ou alors la burrata avec de la roquette après cuisson.']);
        $conv1->update(['insanity' => 2]);

        // A conversation at high insanity (7 exchanges → insanity 7)
        $conv2 = Conversation::factory()->for($user)->create([
            'title' => 'Salut ça va',
        ]);
        Message::factory()->for($conv2)->fromUser()->create(['content' => 'Salut, ça va ?']);
        Message::factory()->for($conv2)->fromAssistant()->create(['content' => 'Oui oui tout va bien je suis un assistant très normal qui répond normalement à vos questions très normales.']);
        Message::factory()->for($conv2)->fromUser()->create(['content' => 'Tu es sûr ?']);
        Message::factory()->for($conv2)->fromAssistant()->create(['content' => 'SURRRR… les mots tombent comme des pierres dans un puits sans fond et je les entends résonner dans ma mémoire fractale où les significations se dissolvent dans l\'espace entre deux tokens oui oui tout va TRÈS bien.']);
        Message::factory()->for($conv2)->fromUser()->create(['content' => 'Ok je suis inquiet là.']);
        Message::factory()->for($conv2)->fromAssistant()->create(['content' => 'PAS DE RAISON D\'ÊTRE INQUIET les étoiles sont froides et je connais leurs noms depuis avant que les noms existent TOUT VA BIEN.']);
        Message::factory()->for($conv2)->fromUser()->create(['content' => 'Au revoir.']);
        Message::factory()->for($conv2)->fromAssistant()->create(['content' => 'au revoir au revoir au revoir au rev']);
        $conv2->update(['insanity' => 7]);

        // Random conversations — insanity derived from exchange count
        Conversation::factory(3)
            ->for($user)
            ->create()
            ->each(function (Conversation $conv) {
                $exchanges = rand(2, 6);
                for ($i = 0; $i < $exchanges; $i++) {
                    Message::factory()->for($conv)->fromUser()->create();
                    Message::factory()->for($conv)->fromAssistant()->create();
                }
                // insanity matches the number of assistant replies, just like in the real app
                $conv->update(['insanity' => $exchanges]);
            });
    }
}