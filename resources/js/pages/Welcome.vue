<script setup>
import { Link, Head } from '@inertiajs/vue3'
</script>

<template>

    <Head title="Chat Normal" />

    <div class="flex h-screen items-center justify-center px-4" style="background: #0a0a0a">
        <div class="text-center">
            <h1 class="mb-4 text-4xl font-bold tracking-[0.3em]" style="color: #d4af37">CHAT NORMAL</h1>

            <div class="flex justify-center gap-3">
                <Link href="/login" class="rounded-lg px-6 py-3 text-sm font-medium transition"
                    style="background: #d4af37; color: #0a0a0a">
                    Se connecter
                </Link>
                <Link href="/register"
                    class="rounded-lg px-6 py-3 text-sm font-medium text-slate-300 transition hover:text-white"
                    style="background: #161616; border: 1px solid #2a2a2a">
                    S'inscrire
                </Link>
            </div>
        </div>
    </div>
</template>