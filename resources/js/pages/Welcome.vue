<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
    <div class="flex h-screen items-center justify-center bg-neutral-950">
        <div class="text-center">
            <h1 class="text-4xl font-bold text-white mb-6">💬 Mon Chat</h1>
            <p class="text-neutral-400 mb-8">Un clone ChatGPT avec streaming en temps réel</p>

            <div class="flex gap-4 justify-center">
                <Link href="/login" class="rounded-lg bg-blue-600 px-6 py-3 text-white transition hover:bg-blue-700">
                    Se connecter
                </Link>
                <Link href="/register"
                    class="rounded-lg bg-neutral-700 px-6 py-3 text-white transition hover:bg-neutral-600">
                    S'inscrire
                </Link>
            </div>
        </div>
    </div>
</template>