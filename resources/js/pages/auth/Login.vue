<script setup lang="ts">
import { Form, Head, Link } from '@inertiajs/vue3'
import InputError from '@/components/InputError.vue'
import PasswordInput from '@/components/PasswordInput.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Spinner } from '@/components/ui/spinner'

defineProps<{
    status?: string
    canResetPassword: boolean
}>()
</script>

<template>

    <Head title="Connexion" />

    <div class="flex min-h-screen items-center justify-center bg-neutral-950 px-4">
        <div class="w-full max-w-sm space-y-8">
            <!-- Branding -->
            <div class="text-center">
                <h1 class="text-3xl font-bold text-white">💬 Mon Chat</h1>
                <p class="mt-2 text-sm text-neutral-400">Connectez-vous pour continuer</p>
            </div>

            <!-- Message de statut -->
            <div v-if="status"
                class="rounded-lg bg-green-900/30 border border-green-800 px-4 py-3 text-sm text-green-300">
                {{ status }}
            </div>

            <!-- Formulaire -->
            <Form method="post" class="space-y-6">
                <div class="space-y-4">
                    <!-- Email -->
                    <div class="space-y-2">
                        <Label for="email" class="text-sm font-medium text-neutral-300">Email</Label>
                        <Input id="email" type="email" name="email" required autofocus placeholder="vous@exemple.com"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500" />
                        <InputError name="email" />
                    </div>

                    <!-- Mot de passe -->
                    <div class="space-y-2">
                        <div class="flex items-center justify-between">
                            <Label for="password" class="text-sm font-medium text-neutral-300">Mot de passe</Label>
                        </div>
                        <PasswordInput id="password" name="password" required placeholder="Votre mot de passe"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500" />
                        <InputError name="password" />
                    </div>
                </div>

                <!-- Bouton -->
                <Button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white">
                    Connexion
                </Button>
            </Form>

            <!-- Lien inscription -->
            <div class="text-center text-sm text-neutral-400">
                Pas encore de compte ?
                <Link href="/register" class="text-blue-400 hover:text-blue-300 font-medium">
                    S'inscrire
                </Link>
            </div>
        </div>
    </div>
</template>