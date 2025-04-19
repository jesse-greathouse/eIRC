<script setup lang="ts">
import { ref } from 'vue';
import type { ChatTab } from '@/types/chat';

const props = defineProps<{
    tabs: ChatTab[];
    activeTab: Ref<string>;
}>();

const emit = defineEmits<{
    (e: 'update-tab', tabId: string): void;
}>();
</script>

<template>
    <div class="p-4 space-y-2">
        <h2 class="text-sm font-semibold text-gray-600 dark:text-gray-300 uppercase tracking-wide">
            Channels
        </h2>

        <button v-for="tab in props.tabs" :key="tab.id" @click="emit('update-tab', tab.id)"
            class="block w-full text-left px-2 py-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700"
            :class="{ 'bg-gray-300 dark:bg-gray-700 font-semibold': tab.id === props.activeTab }">
            {{ tab.label }}
        </button>
    </div>
</template>
