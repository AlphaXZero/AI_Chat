<script setup>
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import { usePage, Link, Head, router } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { useStream } from '@laravel/stream-vue'
import AiSettingsModal from '@/pages/Ask/AiSettingsModal.vue'

const showSettings = ref(false)
const page = usePage()
const props = defineProps({
    models: Array,
    selectedModel: String,
    conversation: Object,
    messages: Array,
    error: String,
})

// champ de saisie + modèle sélectionné
const message = ref('')
const model = ref(props.selectedModel)

// le message que l'utilisateur vient d'envoyer (affiché immédiatement)
const pendingUserMessage = ref('')

// id de conversation renvoyé par le serveur via le header X-Conversation-Id
const newConversationId = ref(null)

const { data, isStreaming, isFetching, send } = useStream('/ask', {
    onResponse: (response) => {
        // récupère l'id de la conversation depuis le header de la réponse
        const id = response.headers.get('X-Conversation-Id')
        if (id) newConversationId.value = id
    },
    onFinish: () => {
        const targetId = newConversationId.value ?? props.conversation?.id
        message.value = ''
        pendingUserMessage.value = ''

        if (props.conversation?.id) {
            // déjà sur une conversation : on recharge pour récupérer le message stocké + titre
            router.reload()
        } else if (targetId) {
            // nouvelle conversation : on va sur sa page dédiée
            router.visit(`/conversations/${targetId}`)
        } else {
            router.reload()
        }
    },
    onError: (err) => {
        console.error('Erreur streaming:', err)
        pendingUserMessage.value = ''
    },
})

// contenu en streaming, nettoyé des marqueurs reasoning
const streamingContent = computed(() => {
    if (!data.value) return ''
    return data.value.replace(/\[REASONING\][\s\S]*?\[\/REASONING\]/g, '').trim()
})

const submit = () => {
    if (!message.value.trim()) return
    pendingUserMessage.value = message.value
    const toSend = message.value
    message.value = ''   // vide le champ tout de suite
    send({
        message: toSend,
        model: model.value,
        conversation_id: props.conversation?.id ?? null,
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

            <!-- Bouton réglages en bas de la sidebar -->
            <button @click="showSettings = true"
                class="mt-auto rounded-lg px-3 py-2 text-left text-sm text-neutral-300 transition hover:bg-neutral-800">
                ⚙️ Instructions personnalisées
            </button>
        </aside>

        <!-- Contenu principal -->
        <main class="flex-1 overflow-y-auto">
            <div class="mx-auto max-w-3xl space-y-6 px-4 py-10">
                <h1 class="text-2xl font-bold">Poser une question</h1>

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

                    <!-- Messages déjà stockés -->
                    <div v-for="msg in props.messages" :key="msg.id" :class="msg.role === 'user'
                        ? 'ml-auto max-w-[80%] rounded-xl bg-blue-600/20 border border-blue-800/40 p-4'
                        : 'mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4'">
                        <MarkdownRenderer :content="msg.content" />
                    </div>

                    <!-- Message user en cours d'envoi (affiché immédiatement) -->
                    <div v-if="pendingUserMessage"
                        class="ml-auto max-w-[80%] rounded-xl bg-blue-600/20 border border-blue-800/40 p-4">
                        <MarkdownRenderer :content="pendingUserMessage" />
                    </div>

                    <!-- Réponse en cours de streaming (SEULEMENT pendant le stream actif) -->
                    <div v-if="isStreaming || isFetching"
                        class="mr-auto max-w-[80%] rounded-xl bg-neutral-900 border border-neutral-700 p-4">
                        <MarkdownRenderer v-if="streamingContent" :content="streamingContent" />
                        <span v-else class="flex gap-1.5">
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
                        <textarea v-model="message" rows="4"
                            class="w-full rounded-md border border-neutral-700 bg-neutral-900 p-2"
                            placeholder="Posez votre question..." id="message" />
                    </div>

                    <!-- Bouton -->
                    <button @click="submit" :disabled="isStreaming || isFetching"
                        class="rounded-md bg-blue-600 px-4 py-2 text-white transition hover:bg-blue-700 disabled:opacity-50">
                        {{ isFetching ? 'Connexion...' : isStreaming ? 'Génération...' : 'Envoyer' }}
                    </button>
                </div>
            </div>
        </main>

        <!-- Modale réglages -->
        <AiSettingsModal :open="showSettings" :profile="page.props.aiProfile" :shortcuts="page.props.shortcuts"
            @close="showSettings = false" />
    </div>
</template>