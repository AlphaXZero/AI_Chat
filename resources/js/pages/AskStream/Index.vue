<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head } from '@inertiajs/vue3'
import { useStream } from '@laravel/stream-vue'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'

const props = defineProps<{
    models: Array<{ id: string; name: string }>
    selectedModel: string
}>()

// State
const message = ref('')
const model = ref(props.selectedModel ?? 'openai/gpt-4o-mini')
const temperature = ref(1.0)
const reasoningEffort = ref<'low' | 'medium' | 'high' | null>(null)

/**
 * useStream hook - concatène automatiquement les chunks dans `data`.
 * Le backend envoie du texte avec marqueurs [REASONING]...[/REASONING]
 */
const { data, isFetching, isStreaming, send, cancel } = useStream('/ask-stream', {
    onFinish: () => {
        message.value = ''
    },
    onError: (err: Error) => {
        console.error('Erreur streaming:', err)
    },
})

/**
 * Contenu principal, sans les blocs de reasoning.
 */
const streamedContent = computed(() => {
    if (!data.value) return ''
    return data.value
        .replace(/\[REASONING\][\s\S]*?\[\/REASONING\]/g, '')
        .trim()
})

/**
 * Trace de raisonnement extraite des marqueurs.
 */
const streamedReasoning = computed(() => {
    if (!data.value) return ''
    const matches = data.value.match(/\[REASONING\]([\s\S]*?)\[\/REASONING\]/g)
    if (!matches) return ''
    return matches
        .map((m) => m.replace(/\[REASONING\]/g, '').replace(/\[\/REASONING\]/g, ''))
        .join('')
})

const submit = () => {
    if (!message.value.trim()) return
    send({
        message: message.value,
        model: model.value,
        temperature: temperature.value,
        reasoning_effort: reasoningEffort.value,
    })
}
</script>

<template>

    <Head title="Chat en streaming" />

    <div class="min-h-screen bg-neutral-950 text-neutral-100">
        <div class="mx-auto max-w-3xl space-y-6 px-4 py-10">
            <h1 class="text-2xl font-bold">Chat en streaming</h1>

            <!-- Formulaire -->
            <div class="space-y-4">
                <!-- Sélecteur de modèle -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Modèle</label>
                    <select v-model="model" class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2">
                        <option v-for="m in props.models" :key="m.id" :value="m.id">
                            {{ m.name }}
                        </option>
                    </select>
                </div>

                <!-- Champ question -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Votre question</label>
                    <textarea v-model="message" rows="4"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2"
                        placeholder="Posez votre question..." />
                </div>

                <!-- Boutons -->
                <div class="flex gap-2">
                    <button @click="submit" :disabled="isStreaming || isFetching"
                        class="rounded-md bg-blue-600 px-4 py-2 text-white transition hover:bg-blue-700 disabled:opacity-50">
                        {{ isFetching ? 'Connexion...' : isStreaming ? 'Génération...' : 'Envoyer' }}
                    </button>
                    <button v-if="isStreaming" @click="cancel"
                        class="rounded-md border border-neutral-700 px-4 py-2 text-neutral-300 transition hover:bg-neutral-800">
                        Annuler
                    </button>
                </div>
            </div>

            <!-- Trace de raisonnement (si le modèle en produit) -->
            <details v-if="streamedReasoning" class="rounded-xl border border-neutral-800 bg-neutral-900/50 p-4">
                <summary class="cursor-pointer text-sm font-medium text-neutral-400">
                    Trace de raisonnement
                </summary>
                <pre class="mt-2 whitespace-pre-wrap text-xs text-neutral-500">{{ streamedReasoning }}</pre>
            </details>

            <!-- Réponse en streaming -->
            <div v-if="streamedContent" class="rounded-xl border border-neutral-700 bg-neutral-900 p-4">
                <MarkdownRenderer :content="streamedContent" />
            </div>
        </div>
    </div>
</template>