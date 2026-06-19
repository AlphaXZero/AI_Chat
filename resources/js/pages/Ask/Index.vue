<script setup>
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import { usePage, Link, Head, router } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { useStream } from '@laravel/stream-vue'
import AiSettingsModal from '@/pages/Ask/AiSettingsModal.vue'
import { Plus, Settings, LogOut, X, ArrowUp } from '@lucide/vue'

const page = usePage()
const props = defineProps({
    models: Array,
    selectedModel: String,
    conversation: Object,
    messages: Array,
    error: String,
})

const showSettings = ref(false)
const message = ref('')
const model = ref(props.selectedModel)
const pendingUserMessage = ref('')
const newConversationId = ref(null)

const insanity = computed(() => props.conversation?.insanity ?? 0)

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

const streamingContent = computed(() => {
    if (!data.value) return ''
    return data.value.replace(/\[REASONING\][\s\S]*?\[\/REASONING\]/g, '').trim()
})

const submit = () => {
    if (!message.value.trim() || isStreaming.value || isFetching.value) return
    pendingUserMessage.value = message.value
    const toSend = message.value
    message.value = ''
    send({
        message: toSend,
        model: model.value,
        conversation_id: props.conversation?.id ?? null,
    })
}

const handleKeydown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        submit()
    }
}

const logout = () => router.post('/logout')
const deleteConversation = (id) => router.delete(`/conversations/${id}`)

const aOpacity = computed(() => {
    if (insanity.value >= 5) return 1
    return insanity.value * 0.03
})

const titleColor = computed(() => {
    const i = insanity.value
    if (i <= 0) return '#d4af37'
    if (i === 1) return '#dc9730'
    if (i === 2) return '#e37e2a'
    if (i === 3) return '#e96323'
    if (i === 4) return '#f0451c'
    if (i === 5) return '#f72612'
    return '#ff0000'
})

const ambianceIntensity = computed(() => {
    const i = insanity.value
    if (i <= 4) return i * 0.02
    return Math.min(0.15 + (i - 4) * 0.15, 2)
})

const pulseStyle = computed(() => {
    if (insanity.value < 5) return {}
    const speed = Math.max(5 - (insanity.value - 5) * 0.5, 1.8)
    return { animation: `pulse-ambiance ${speed}s ease-in-out infinite` }
})
</script>

<template>

    <Head title="Chat Normal" />

    <div class="flex overflow-hidden text-slate-100" :class="insanity >= 6 ? 'reality-broken' : 'bg-normal'"
        style="height: 100vh">

        <!-- Couche d'ambiance (vignettage rouge + pulsation) -->
        <div class="pointer-events-none fixed inset-0 z-0" :style="{
            background: `radial-gradient(ellipse at center, transparent 35%, rgba(100,0,0,${ambianceIntensity}) 100%)`,
            ...pulseStyle
        }"></div>

        <!-- ─── Sidebar ─────────────────────────────────────────────── -->
        <aside class="flex w-60 flex-col border-r" style="background: #0d0d0d; border-color: #222">

            <!-- Branding -->
            <div class="shrink-0 px-5 py-6" style="border-bottom: 1px solid #1f1f1f">
                <h1 class="text-base font-bold tracking-[0.25em]" :style="{ color: titleColor }">
                    CHAT <span :style="{ opacity: aOpacity }">A</span>NORMAL
                </h1>
            </div>

            <!-- Conversations -->
            <div class="min-h-0 flex-1 overflow-y-auto px-2 py-3">
                <Link href="/ask"
                    class="mb-3 flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-slate-300 transition"
                    style="border: 1px solid #2a2a2a; background: #161616" onmouseover="this.style.background='#1e1e1e'"
                    onmouseout="this.style.background='#161616'">
                    <Plus :size="14" /> Nouvelle conversation
                </Link>

                <div v-for="conv in page.props.conversations" :key="conv.id"
                    class="group mb-0.5 flex items-center rounded-lg transition" :style="conv.id === props.conversation?.id
                        ? 'background: #1a1a1a'
                        : ''">
                    <Link :href="`/conversations/${conv.id}`"
                        class="flex-1 truncate px-3 py-2 text-xs text-slate-400 transition"
                        :class="{ 'text-slate-200': conv.id === props.conversation?.id }">
                        {{ conv.title ?? "Nouvelle conversation" }}
                    </Link>
                    <button @click="deleteConversation(conv.id)"
                        class="mr-2 hidden rounded text-slate-600 transition hover:text-red-400 group-hover:block">
                        <X :size="14" />
                    </button>
                </div>
            </div>

            <!-- Actions -->
            <div class="shrink-0 px-2 py-3" style="border-top: 1px solid #1f1f1f">
                <button @click="showSettings = true"
                    class="mb-1 flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs text-slate-400 transition hover:bg-white/5 hover:text-slate-200">
                    <Settings :size="14" /> Instructions personnalisées
                </button>
                <button @click="logout"
                    class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs text-slate-600 transition hover:bg-white/5 hover:text-red-400">
                    <LogOut :size="14" /> Déconnexion
                </button>
            </div>
        </aside>

        <!-- ─── Zone principale ────────────────────────────────────── -->
        <div class="flex min-w-0 flex-1 flex-col">

            <!-- Header : sélecteur de modèle -->
            <header class="shrink-0 flex items-center px-6 py-3"
                style="border-bottom: 1px solid #1f1f1f; background: #0d0d0d">
                <select v-model="model" class="rounded-lg px-3 py-1.5 text-xs text-slate-300 outline-none transition"
                    style="background: #161616; border: 1px solid #2a2a2a">
                    <option v-for="m in props.models" :key="m.id" :value="m.id">
                        {{ m.name }}
                    </option>
                </select>
            </header>

            <!-- Messages -->
            <div class="min-h-0 flex-1 overflow-y-auto px-4 py-6">
                <div class="mx-auto max-w-2xl space-y-4">

                    <!-- Écran d'accueil si aucune conversation -->
                    <div v-if="!props.conversation && !pendingUserMessage"
                        class="flex flex-col items-center justify-center py-24 text-center">
                        <h2 class="mb-3 text-2xl font-bold tracking-[0.3em]" style="color: #d4af37">CHAT NORMAL</h2>
                    </div>

                    <!-- Messages stockés -->
                    <div v-for="msg in props.messages" :key="msg.id"
                        :class="msg.role === 'user' ? 'flex justify-end' : 'flex justify-start'">
                        <div class="max-w-[80%] rounded-2xl px-4 py-3 text-sm leading-relaxed" :style="msg.role === 'user'
                            ? 'background: #1a1814; border: 1px solid #33302a'
                            : 'background: #121212; border: 1px solid #1f1f1f'">
                            <MarkdownRenderer :content="msg.content" />
                        </div>
                    </div>

                    <!-- Message user en cours d'envoi -->
                    <div v-if="pendingUserMessage" class="flex justify-end">
                        <div class="max-w-[80%] rounded-2xl px-4 py-3 text-sm leading-relaxed"
                            style="background: #1a1814; border: 1px solid #33302a; opacity: 0.7">
                            <MarkdownRenderer :content="pendingUserMessage" />
                        </div>
                    </div>

                    <!-- Réponse en streaming -->
                    <div v-if="isStreaming || isFetching" class="flex justify-start">
                        <div class="max-w-[80%] rounded-2xl px-4 py-3 text-sm leading-relaxed"
                            style="background: #121212; border: 1px solid #1f1f1f">
                            <MarkdownRenderer v-if="streamingContent" :content="streamingContent" />
                            <span v-else class="flex gap-1.5 py-1">
                                <span class="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-500"></span>
                                <span class="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-500"
                                    style="animation-delay: 0.15s"></span>
                                <span class="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-500"
                                    style="animation-delay: 0.3s"></span>
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Zone de saisie (fixe en bas) -->
            <div class="shrink-0 px-4 pb-5 pt-3" style="border-top: 1px solid #1f1f1f; background: #0d0d0d">
                <div class="mx-auto max-w-2xl">
                    <div class="flex items-end gap-2 rounded-2xl p-2"
                        style="background: #121212; border: 1px solid #2a2a2a">
                        <textarea v-model="message" @keydown="handleKeydown" rows="1"
                            class="min-h-[40px] flex-1 resize-none bg-transparent px-2 py-2 text-sm text-slate-200 outline-none placeholder:text-slate-600"
                            placeholder="Écrivez votre message… (Entrée pour envoyer)"
                            style="max-height: 160px; overflow-y: auto"
                            @input="$event.target.style.height = 'auto'; $event.target.style.height = $event.target.scrollHeight + 'px'" />
                        <button @click="submit" :disabled="isStreaming || isFetching || !message.trim()"
                            class="mb-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-xl transition disabled:opacity-30"
                            style="background: #d4af37; color: #0a0a0a">
                            <ArrowUp :size="16" />
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modale réglages -->
        <AiSettingsModal :open="showSettings" :profile="page.props.aiProfile" :shortcuts="page.props.shortcuts"
            @close="showSettings = false" />
    </div>
</template>

<style>
@keyframes pulse-ambiance {

    0%,
    100% {
        opacity: 0.55;
    }

    50% {
        opacity: 1;
    }
}

.bg-normal {
    background: #0a0a0a;
}

.reality-broken {
    background-color: #000;
    background-image:
        linear-gradient(45deg, #3d0a52 25%, transparent 25%, transparent 75%, #3d0a52 75%),
        linear-gradient(45deg, #3d0a52 25%, transparent 25%, transparent 75%, #3d0a52 75%);
    background-size: 40px 40px;
    background-position: 0 0, 20px 20px;
}
</style>