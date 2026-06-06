<script setup>
import { computed } from 'vue'
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import 'highlight.js/styles/github-dark.css'

const props = defineProps({
    content: { type: String, default: '' },
})

const md = new MarkdownIt({
    highlight(str, lang) {
        if (lang && hljs.getLanguage(lang)) {
            try {
                return hljs.highlight(str, { language: lang }).value
            } catch (e) {
                // ignore
            }
        }
        return ''
    },
})

const rendered = computed(() => md.render(props.content ?? ''))
</script>

<template>
    <div class="prose dark:prose-invert prose-slate max-w-none" v-html="rendered" />
</template>
