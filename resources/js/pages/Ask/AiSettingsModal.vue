<script setup>
import { useForm } from '@inertiajs/vue3'
import { X, Plus } from '@lucide/vue'

const props = defineProps({
    open: Boolean,
    profile: { type: Object, default: () => ({}) },
    shortcuts: { type: Array, default: () => [] },
})

const emit = defineEmits(['close'])

const form = useForm({
    profile: {
        emojis: props.profile.emojis ?? 'non',
        tone: props.profile.tone ?? 'neutre',
        length: props.profile.length ?? 'normal',
    },
    shortcuts: [...props.shortcuts],
})

const addShortcut = () => {
    form.shortcuts.push({ command: '', instruction: '' })
}

const removeShortcut = (index) => {
    form.shortcuts.splice(index, 1)
}

const save = () => {
    form.patch('/settings/ai', { onSuccess: () => emit('close') })
}
</script>

<template>
    <!-- Overlay -->
    <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4"
        style="background: rgba(0,0,0,0.75)" @click.self="emit('close')">

        <!-- Fenêtre -->
        <div class="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-2xl p-6 text-slate-100"
            style="background: #0d0d0d; border: 1px solid #2a2a2a">

            <!-- En-tête -->
            <div class="mb-6 flex items-center justify-between">
                <h2 class="text-base font-bold tracking-[0.15em]" style="color: #d4af37">INSTRUCTIONS</h2>
                <button @click="emit('close')" class="text-slate-500 transition hover:text-slate-200">
                    <X :size="18" />
                </button>
            </div>

            <!-- PROFIL -->
            <section class="space-y-4">
                <h3 class="text-xs font-medium uppercase tracking-wider text-slate-500">Comportement de l'assistant</h3>

                <div>
                    <label class="mb-1.5 block text-sm text-slate-300">Émojis</label>
                    <select v-model="form.profile.emojis"
                        class="w-full rounded-lg px-3 py-2 text-sm text-slate-200 outline-none transition"
                        style="background: #161616; border: 1px solid #2a2a2a">
                        <option value="non">Aucun</option>
                        <option value="peu">Peu</option>
                        <option value="beaucoup">Beaucoup</option>
                    </select>
                </div>

                <div>
                    <label class="mb-1.5 block text-sm text-slate-300">Ton</label>
                    <select v-model="form.profile.tone"
                        class="w-full rounded-lg px-3 py-2 text-sm text-slate-200 outline-none transition"
                        style="background: #161616; border: 1px solid #2a2a2a">
                        <option value="neutre">Neutre</option>
                        <option value="formel">Formel</option>
                        <option value="casual">Décontracté</option>
                        <option value="technique">Technique</option>
                    </select>
                </div>

                <div>
                    <label class="mb-1.5 block text-sm text-slate-300">Longueur des réponses</label>
                    <select v-model="form.profile.length"
                        class="w-full rounded-lg px-3 py-2 text-sm text-slate-200 outline-none transition"
                        style="background: #161616; border: 1px solid #2a2a2a">
                        <option value="concis">Concis</option>
                        <option value="normal">Normal</option>
                        <option value="detaille">Détaillé</option>
                    </select>
                </div>
            </section>

            <!-- RACCOURCIS -->
            <section class="mt-6 space-y-3">
                <div class="flex items-center justify-between">
                    <h3 class="text-xs font-medium uppercase tracking-wider text-slate-500">Raccourcis</h3>
                    <button @click="addShortcut"
                        class="flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs text-slate-300 transition hover:text-slate-100"
                        style="background: #161616; border: 1px solid #2a2a2a">
                        <Plus :size="12" /> Ajouter
                    </button>
                </div>

                <div v-for="(sc, index) in form.shortcuts" :key="index" class="flex items-start gap-2">
                    <input v-model="sc.command" placeholder="/review"
                        class="w-28 rounded-lg px-3 py-2 text-sm text-slate-200 outline-none placeholder:text-slate-600"
                        style="background: #161616; border: 1px solid #2a2a2a" />
                    <textarea v-model="sc.instruction" placeholder="Instruction à exécuter..." rows="2"
                        class="flex-1 rounded-lg px-3 py-2 text-sm text-slate-200 outline-none placeholder:text-slate-600"
                        style="background: #161616; border: 1px solid #2a2a2a" />
                    <button @click="removeShortcut(index)" class="pt-2 text-slate-600 transition hover:text-red-400">
                        <X :size="16" />
                    </button>
                </div>

                <p v-if="form.shortcuts.length === 0" class="text-xs text-slate-600">
                    Aucun raccourci. Cliquez sur « Ajouter ».
                </p>
            </section>

            <!-- ACTIONS -->
            <div class="mt-8 flex justify-end gap-2">
                <button @click="emit('close')"
                    class="rounded-lg px-4 py-2 text-sm text-slate-500 transition hover:text-slate-200">
                    Annuler
                </button>
                <button @click="save" :disabled="form.processing"
                    class="rounded-lg px-4 py-2 text-sm font-medium transition disabled:opacity-50"
                    style="background: #d4af37; color: #0a0a0a">
                    {{ form.processing ? 'Enregistrement...' : 'Enregistrer' }}
                </button>
            </div>
        </div>
    </div>
</template>