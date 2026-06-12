<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import { usePage, Link } from '@inertiajs/vue3'

const page = usePage()
const props = defineProps({
    models: Array,
    selectedModel: String,
    conversation: Object,
    messages: Array,
    error: String,
})

const form = useForm({
    message: "",
    model: props.selectedModel,
    conversation_id: props.conversation?.id ?? null,
})

const submit = () => {
    form.post('/ask', {
        preserveScroll: true,
        onSuccess: () => {
            form.reset('message')
            form.conversation_id = props.conversation?.id ?? null
        },
    })
}
</script>
<template>

    <Head title="Poser une question" />

    <div class="flex min-h-screen bg-neutral-950 text-neutral-100">
        <!-- Sidebar -->
        <aside class="flex w-64 flex-col gap-1 border-r border-neutral-800 bg-neutral-900 p-3 overflow-y-auto">
            <Link href="/ask"
                class="mb-3 rounded-lg bg-blue-600 px-3 py-2 text-center text-sm font-medium text-white transition hover:bg-blue-700">
                + Nouvelle conversation
            </Link>

            <Link v-for="conv in page.props.conversations" :key="conv.id" :href="`/conversations/${conv.id}`"
                class="truncate rounded-lg px-3 py-2 text-sm text-neutral-300 transition hover:bg-neutral-800"
                :class="{ 'bg-neutral-800 text-white': conv.id === props.conversation?.id }">
                {{ conv.title ?? "Nouvelle conversation" }}
            </Link>
        </aside>

        <!-- Contenu principal -->
        <main class="flex-1 overflow-y-auto">
            <div class="mx-auto max-w-3xl space-y-6 px-4 py-10">
                <h1 class="text-2xl font-bold">Poser une question</h1>

                <!-- Formulaire -->
                <div class="space-y-4">
                    <!-- Sélecteur de modèle -->
                    <div>
                        <label class="mb-1 block text-sm font-medium">Modèle</label>
                        <select v-model="form.model"
                            class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2">
                            <option v-for="model in props.models" :key="model.id" :value="model.id">
                                {{ model.name }}
                            </option>
                        </select>
                    </div>

                    <div v-for="message in props.messages" :key="message.id" :class="message.role === 'user'
                        ? 'ml-auto max-w-[80%] rounded-xl bg-blue-600/20 border border-blue-800/40 p-4'
                        : 'mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4'">
                        <MarkdownRenderer :content="message.content" />
                    </div>

                    <!-- Loader pendant l'appel API -->
                    <div v-if="form.processing"
                        class="mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4">
                        <span class="flex gap-1.5">
                            <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500"></span>
                            <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500"
                                style="animation-delay: 0.15s"></span>
                            <span class="h-2 w-2 animate-bounce rounded-full bg-neutral-500"
                                style="animation-delay: 0.3s"></span>
                        </span>
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
            </div>
        </main>
    </div>
</template>