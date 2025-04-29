<script setup lang="ts">
import type { Channel } from '@/irc/models/Channel';

defineProps<{
    channels: Channel[];
}>();

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();
</script>

<template>
    <div class="flex flex-col flex-1 overflow-y-auto space-y-2 p-4">
        <h2 class="text-sm font-semibold text-gray-600 dark:text-gray-300 uppercase tracking-wide">
            Channels
        </h2>
        <button
            v-for="channel in channels" :key="channel.name" type="button"
            class="inline-flex items-center justify-between w-full px-4 py-2 text-sm font-medium text-left text-gray-900 bg-gray-100 rounded-lg hover:bg-gray-200 dark:bg-gray-700 dark:text-white dark:hover:bg-gray-600"
            @click="emit('switch-tab', channel.name)">
            <span>{{ channel.name }}</span>
            <span
                class="inline-flex items-center justify-center w-5 h-5 ms-2 text-xs font-semibold text-blue-800 bg-blue-200 rounded-full dark:bg-blue-500 dark:text-white">
                {{ channel.users.size }}
            </span>
        </button>
    </div>
</template>
