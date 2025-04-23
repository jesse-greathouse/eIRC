<script setup lang="ts">
import BasePaneHeader from './BasePaneHeader.vue';

const { channel, topic } = defineProps<{
    channel?: string;
    topic?: string;
}>();
</script>

<template>
    <BasePaneHeader>
        <div class="flex flex-col">
            <span class="font-bold text-lg text-gray-800 dark:text-gray-100">{{ channel }}</span>
            <span class="text-sm text-gray-500 dark:text-gray-400">
                {{ topic || 'No topic set' }}
            </span>
        </div>
    </BasePaneHeader>
</template>
