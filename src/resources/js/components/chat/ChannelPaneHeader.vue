<script setup lang="ts">
import { computed } from 'vue';
import { linkifyHtml } from '@/composables/useLinkify';
import BasePaneHeader from './BasePaneHeader.vue';

const { channel, topic } = defineProps<{
    channel?: string;
    topic?: string;
}>();

const linkifiedTopic = computed(() => topic ? linkifyHtml(topic) : 'No topic set');
</script>

<template>
    <BasePaneHeader>
        <div class="flex flex-col">
            <span class="font-bold text-lg text-gray-800 dark:text-gray-100">{{ channel }}</span>
            <span class="text-sm text-gray-500 dark:text-gray-400" v-html="linkifiedTopic"></span>
        </div>
    </BasePaneHeader>
</template>
