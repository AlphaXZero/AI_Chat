<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'

const props = defineProps({
    models: Array,
    selectedModel: String,
    message: String,
    response: String,
    error: String,
})

const form = useForm({
    message: props.message ?? '',
    model: props.selectedModel,
    conversation_id: props.conversation?.id ?? null,
})

const submit = () => {
    form.post('/ask', {
        preserveScroll: true,
    })
}
</script>
<template>

    <Head title="Poser une question" />

    <div class="min-h-screen bg-neutral-950 text-neutral-100">
        <div class="mx-auto max-w-3xl space-y-6 px-4 py-10">
            <h1 class="text-2xl font-bold">Poser une question</h1>

            <!-- Formulaire -->
            <div class="space-y-4">
                <!-- Sélecteur de modèle -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Modèle</label>
                    <select v-model="form.model" class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2">
                        <option v-for="model in props.models" :key="model.id" :value="model.id">
                            {{ model.name }}
                        </option>
                    </select>
                </div>

                <!-- Champ question -->
                <div>
                    <label class="mb-1 block text-sm font-medium">Votre question</label>
                    <textarea v-model="form.message" rows="4"
                        class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2"
                        placeholder="Posez votre question..." />
                    <p v-if="form.errors.message" class="mt-1 text-sm text-red-500">
                        {{ form.errors.message }}
                    </p>
                </div>

                <!-- Bouton -->
                <button @click="submit" :disabled="form.processing"
                    class="rounded-md bg-blue-600 px-4 py-2 text-white transition hover:bg-blue-700 disabled:opacity-50">
                    {{ form.processing ? 'Envoi...' : 'Envoyer' }}
                </button>
            </div>

            <!-- Erreur API -->
            <div v-if="props.error" class="rounded-md bg-red-950/30 p-4 text-red-400">
                Erreur : {{ props.error }}
            </div>

            <!-- Réponse -->
            <div v-if="props.response" class="rounded-xl border border-neutral-700 p-4">
                <MarkdownRenderer :content="props.response" />
            </div>
        </div>
    </div>
</template>