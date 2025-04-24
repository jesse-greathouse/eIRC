<script setup lang="ts">
import { computed } from 'vue';
import type { User } from '@/irc/models/User';

const props = defineProps<{
    user: User;
}>();

const avatarUrl = computed(() => {
    // Placeholder static avatar for now
    return '/avatar-placeholder.png';
});

const username = computed(() => {
    return props.user.nick;
});
</script>

<template>
    <div
        class="flex items-center py-3 sm:py-4 px-2 rounded-lg transition-transform duration-200 ease-in-out hover:shadow-lg hover:-translate-y-1 hover:border hover:border-gray-300 dark:hover:border-gray-600 cursor-pointer"
    >
        <div class="shrink-0">
            <img class="w-8 h-8 rounded-full" :src="avatarUrl" alt="User avatar" />
        </div>
        <div class="flex-1 min-w-0 ms-4">
            <p class="text-sm font-medium text-gray-900 truncate dark:text-white">
                {{ username }}
            </p>
            <p class="text-sm text-gray-500 truncate dark:text-gray-400">
                Online
            </p>
        </div>
    </div>
</template>
