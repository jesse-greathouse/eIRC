<script setup lang="ts">
import type { ChatTab } from '@/types/chat';

const props = defineProps<{
    tabs: ChatTab[];
    activeTab: string;
}>();

const emit = defineEmits<{
    (e: 'update-tab', tabId: string): void;
}>();
</script>

<template>
    <div class="flex flex-col flex-1 overflow-y-auto space-y-2 p-4">
        <h2 class="text-sm font-semibold text-gray-600 dark:text-gray-300 uppercase tracking-wide">
            Channels
        </h2>
        <button v-for="tab in props.tabs" :key="tab.id" @click="emit('update-tab', tab.id)"
            class="block w-full text-left px-2 py-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700"
            :class="{ 'bg-gray-300 dark:bg-gray-700 font-semibold': tab.id === props.activeTab }">

            <!-- Slot support for tab customization -->
            <slot name="tab" :tab="tab">
                {{ tab.label }}
            </slot>
        </button>
    </div>
</template>
