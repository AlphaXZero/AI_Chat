<script setup lang="ts">
import { Form, Head, Link } from '@inertiajs/vue3'
import InputError from '@/components/InputError.vue'
import PasswordInput from '@/components/PasswordInput.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Spinner } from '@/components/ui/spinner'

defineProps<{
    passwordRules: string
}>()
</script>

<template>

    <Head title="Inscription" />

    <div class="flex min-h-screen items-center justify-center bg-neutral-950 px-4">
        <div class="w-full max-w-sm space-y-8">
            <!-- Branding -->
            <div class="text-center">
                <h1 class="text-3xl font-bold text-white">💬 Mon Chat</h1>
                <p class="mt-2 text-sm text-neutral-400">Créez un compte pour commencer</p>
            </div>

            <!-- Formulaire -->
            <Form method="post" class="space-y-6">
                <div class="space-y-4">
                    <!-- Nom -->
                    <div class="space-y-2">
                        <Label for="name" class="text-sm font-medium text-neutral-300">Nom</Label>
                        <Input id="name" type="text" name="name" required autofocus placeholder="Votre nom complet"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500" />
                        <InputError name="name" />
                    </div>

                    <!-- Email -->
                    <div class="space-y-2">
                        <Label for="email" class="text-sm font-medium text-neutral-300">Email</Label>
                        <Input id="email" type="email" name="email" required placeholder="vous@exemple.com"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500" />
                        <InputError name="email" />
                    </div>

                    <!-- Mot de passe -->
                    <div class="space-y-2">
                        <Label for="password" class="text-sm font-medium text-neutral-300">Mot de passe</Label>
                        <PasswordInput id="password" name="password" required placeholder="Au moins 8 caractères"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500"
                            :passwordrules="passwordRules" />
                        <InputError name="password" />
                    </div>

                    <!-- Confirmation mot de passe -->
                    <div class="space-y-2">
                        <Label for="password_confirmation" class="text-sm font-medium text-neutral-300">Confirmer le mot
                            de passe</Label>
                        <PasswordInput id="password_confirmation" name="password_confirmation" required
                            placeholder="Confirmez votre mot de passe"
                            class="bg-neutral-900 border-neutral-800 text-white placeholder:text-neutral-500"
                            :passwordrules="passwordRules" />
                        <InputError name="password_confirmation" />
                    </div>
                </div>

                <!-- Bouton -->
                <Button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white">
                    Créer un compte
                </Button>
            </Form>

            <!-- Lien connexion -->
            <div class="text-center text-sm text-neutral-400">
                Vous avez déjà un compte ?
                <Link href="/login" class="text-blue-400 hover:text-blue-300 font-medium">
                    Se connecter
                </Link>
            </div>
        </div>
    </div>
</template>