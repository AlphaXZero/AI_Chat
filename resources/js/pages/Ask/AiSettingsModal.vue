<script setup>
import { useForm } from '@inertiajs/vue3'

const props = defineProps({
    open: Boolean,
    profile: { type: Object, default: () => ({}) },   // ex: { emojis: 'peu', tone: 'casual' }
    shortcuts: { type: Array, default: () => [] },      // ex: [{ command: '/hi', instruction: 'hello' }]
})

const emit = defineEmits(['close'])

// le formulaire : profil + raccourcis
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
    <!-- overlay : fond sombre cliquable pour fermer -->
    <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
        @click.self="emit('close')">
        <!-- la fenêtre -->
        <div
            class="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-2xl border border-neutral-700 bg-neutral-900 p-6 text-neutral-100">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-lg font-semibold">Instructions personnalisées</h2>
                <button @click="emit('close')" class="text-neutral-400 hover:text-white">✕</button>
            </div>

            <!-- PROFIL -->
            <section class="space-y-4">
                <h3 class="text-sm font-medium text-neutral-400">Comportement de l'assistant</h3>

                <div>
                    <label class="mb-1 block text-sm">Émojis</label>
                    <select v-model="form.profile.emojis"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-800 p-2 text-sm">
                        <option value="non">Aucun</option>
                        <option value="peu">Peu</option>
                        <option value="beaucoup">Beaucoup</option>
                    </select>
                </div>

                <div>
                    <label class="mb-1 block text-sm">Ton</label>
                    <select v-model="form.profile.tone"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-800 p-2 text-sm">
                        <option value="neutre">Neutre</option>
                        <option value="formel">Formel</option>
                        <option value="casual">Décontracté</option>
                        <option value="technique">Technique</option>
                    </select>
                </div>

                <div>
                    <label class="mb-1 block text-sm">Longueur des réponses</label>
                    <select v-model="form.profile.length"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-800 p-2 text-sm">
                        <option value="concis">Concis</option>
                        <option value="normal">Normal</option>
                        <option value="detaille">Détaillé</option>
                    </select>
                </div>
            </section>

            <!-- RACCOURCIS -->
            <section class="mt-6 space-y-3">
                <div class="flex items-center justify-between">
                    <h3 class="text-sm font-medium text-neutral-400">Raccourcis</h3>
                    <button @click="addShortcut"
                        class="rounded-md bg-neutral-700 px-2 py-1 text-xs hover:bg-neutral-600">+ Ajouter</button>
                </div>

                <div v-for="(sc, index) in form.shortcuts" :key="index" class="flex gap-2 items-start">
                    <input v-model="sc.command" placeholder="/review"
                        class="w-28 rounded-md border border-neutral-700 bg-neutral-800 p-2 text-sm" />
                    <textarea v-model="sc.instruction" placeholder="Instruction à exécuter..." rows="2"
                        class="flex-1 rounded-md border border-neutral-700 bg-neutral-800 p-2 text-sm" />
                    <button @click="removeShortcut(index)" class="text-neutral-500 hover:text-red-400 pt-2">✕</button>
                </div>

                <p v-if="form.shortcuts.length === 0" class="text-xs text-neutral-500">
                    Aucun raccourci. Cliquez sur « Ajouter ».
                </p>
            </section>

            <!-- ACTIONS -->
            <div class="mt-6 flex justify-end gap-2">
                <button @click="emit('close')"
                    class="rounded-md px-4 py-2 text-sm text-neutral-400 hover:text-white">Annuler</button>
                <button @click="save" :disabled="form.processing"
                    class="rounded-md bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-50">
                    {{ form.processing ? 'Enregistrement...' : 'Enregistrer' }}
                </button>
            </div>
        </div>
    </div>

</template>