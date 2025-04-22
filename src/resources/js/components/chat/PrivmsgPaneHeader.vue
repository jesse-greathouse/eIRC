<script setup lang="ts">
import BasePaneHeader from './BasePaneHeader.vue';

const { nick, status } = defineProps<{
    nick: string;
    status?: string;
}>();
</script>

<template>
    <BasePaneHeader>
        <div class="flex items-center gap-2">
            <span class="font-bold text-lg text-gray-800 dark:text-gray-100">{{ nick }}</span>
            <span class="text-sm text-gray-500 dark:text-gray-400">{{ status || 'Online' }}</span>
        </div>
    </BasePaneHeader>
</template>
