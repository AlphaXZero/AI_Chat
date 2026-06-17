<script setup>
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import { usePage, Link, Head, router } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { useStream } from '@laravel/stream-vue'
import AiSettingsModal from '@/pages/Ask/AiSettingsModal.vue'

const page = usePage()
const props = defineProps({
    models: Array,
    selectedModel: String,
    conversation: Object,
    messages: Array,
    error: String,
})

const showSettings = ref(false)

// champ de saisie + modèle sélectionné
const message = ref('')
const model = ref(props.selectedModel)

// message en cours d'envoi (affiché immédiatement, avant le rechargement)
const pendingUserMessage = ref('')

// id de conversation renvoyé par le serveur via le header X-Conversation-Id
const newConversationId = ref(null)

const { data, isStreaming, isFetching, send } = useStream('/ask', {
    onResponse: (response) => {
        const id = response.headers.get('X-Conversation-Id')
        if (id) newConversationId.value = id
    },
    onFinish: () => {
        const targetId = newConversationId.value ?? props.conversation?.id
        message.value = ''
        pendingUserMessage.value = ''

        if (props.conversation?.id) {
            router.reload()
        } else if (targetId) {
            router.visit(`/conversations/${targetId}`), {
                only: ['conversation', 'messages', 'conversations'],
            }
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
    message.value = ''
    send({
        message: toSend,
        model: model.value,
        conversation_id: props.conversation?.id ?? null,
    })
}

const logout = () => {
    router.post('/logout')
}
</script>

<template>

    <Head title="Poser une question" />

    <!-- height: 100vh garanti en inline pour borner la hauteur (indispensable au scroll interne) -->
    <div class="flex overflow-hidden bg-neutral-950 text-neutral-100" style="height: 100vh">
        <!-- Sidebar : titre fixe / conversations scrollables / actions fixes -->
        <aside class="flex w-64 flex-col border-r border-neutral-800 bg-neutral-900">
            <!-- Haut : titre / branding (fixe) -->
            <div class="shrink-0 border-b border-neutral-800 p-4">
                <h2 class="text-lg font-bold">💬 Mon Chat</h2>
            </div>

            <!-- Milieu : liste des conversations (scrolle) -->
            <div class="min-h-0 flex-1 overflow-y-auto p-3">
                <Link href="/ask"
                    class="mb-2 block rounded-lg bg-blue-600 px-3 py-2 text-center text-sm font-medium text-white transition hover:bg-blue-700">
                    + Nouvelle conversation
                </Link>

                <div class="flex flex-col gap-1">
                    <Link v-for="conv in page.props.conversations" :key="conv.id" :href="`/conversations/${conv.id}`"
                        class="truncate rounded-lg px-3 py-2 text-sm text-neutral-300 transition hover:bg-neutral-800"
                        :class="{ 'bg-neutral-800 text-white': conv.id === props.conversation?.id }">
                        {{ conv.title ?? "Nouvelle conversation" }}
                    </Link>
                </div>
            </div>

            <!-- Bas : réglages + déconnexion (fixe) -->
            <div class="shrink-0 flex flex-col gap-1 border-t border-neutral-800 p-3">
                <button @click="showSettings = true"
                    class="rounded-lg px-3 py-2 text-left text-sm text-neutral-300 transition hover:bg-neutral-800">
                    ⚙️ Instructions personnalisées
                </button>
                <button @click="logout"
                    class="rounded-lg px-3 py-2 text-left text-sm text-neutral-400 transition hover:bg-neutral-800 hover:text-red-400">
                    Déconnexion
                </button>
            </div>
        </aside>

        <!-- Contenu principal (scrolle indépendamment) -->
        <main class="min-h-0 flex-1 overflow-y-auto">
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

                    <!-- Message user en cours d'envoi -->
                    <div v-if="pendingUserMessage"
                        class="ml-auto max-w-[80%] rounded-xl border border-blue-800/40 bg-blue-600/20 p-4">
                        <MarkdownRenderer :content="pendingUserMessage" />
                    </div>

                    <!-- Réponse en cours de streaming -->
                    <div v-if="isStreaming || isFetching"
                        class="mr-auto max-w-[80%] rounded-xl border border-neutral-700 bg-neutral-900 p-4">
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
                            placeholder="Posez votre question..." />
                    </div>

                    <!-- Bouton envoyer -->
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