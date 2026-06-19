<script setup lang="ts">
import { Form, Head, Link } from '@inertiajs/vue3'
import InputError from '@/components/InputError.vue'
import PasswordInput from '@/components/PasswordInput.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

defineProps<{
    status?: string
    canResetPassword: boolean
}>()
</script>

<template>

    <Head title="Connexion" />

    <div class="flex min-h-screen items-center justify-center px-4" style="background: #0a0a0a">
        <div class="w-full max-w-sm space-y-8">
            <!-- Branding -->
            <div class="text-center">
                <h1 class="text-2xl font-bold tracking-[0.3em]" style="color: #d4af37">CHAT NORMAL</h1>
                <p class="mt-3 text-sm text-slate-500">Connectez-vous pour continuer</p>
            </div>

            <!-- Message de statut -->
            <div v-if="status" class="rounded-lg px-4 py-3 text-sm text-green-300"
                style="background: rgba(20,60,30,0.3); border: 1px solid #2a4a35">
                {{ status }}
            </div>

            <!-- Formulaire -->
            <Form method="post" class="space-y-6">
                <div class="space-y-4">
                    <!-- Email -->
                    <div class="space-y-2">
                        <Label for="email" class="text-sm font-medium text-slate-400">Email</Label>
                        <Input id="email" type="email" name="email" required autofocus placeholder="vous@exemple.com"
                            class="text-slate-200 placeholder:text-slate-600"
                            style="background: #161616; border-color: #2a2a2a" />
                        <InputError name="email" />
                    </div>

                    <!-- Mot de passe -->
                    <div class="space-y-2">
                        <div class="flex items-center justify-between">
                            <Label for="password" class="text-sm font-medium text-slate-400">Mot de passe</Label>
                        </div>
                        <PasswordInput id="password" name="password" required placeholder="Votre mot de passe"
                            class="text-slate-200 placeholder:text-slate-600"
                            style="background: #161616; border-color: #2a2a2a" />
                        <InputError name="password" />
                    </div>
                </div>

                <!-- Bouton -->
                <Button type="submit" class="w-full font-medium" style="background: #d4af37; color: #0a0a0a">
                    Connexion
                </Button>
            </Form>

            <!-- Lien inscription -->
            <div class="text-center text-sm text-slate-500">
                Pas encore de compte ?
                <Link href="/register" class="font-medium" style="color: #d4af37">
                    S'inscrire
                </Link>
            </div>
        </div>
    </div>
</template>