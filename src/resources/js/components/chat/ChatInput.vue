<script setup lang="ts">
import { ref } from 'vue';

const send = (target: string, message: string) => {
    console.log(`message to: ${target}: ${message}`);
}

const props = defineProps<{
    target: string;
}>();

const message = ref('');

function handleSubmit() {
    if (message.value.trim()) {
        send(props.target, message.value.trim());
        message.value = '';
    }
}
</script>

<template>
    <form @submit.prevent="handleSubmit" class="flex w-full h-16">
        <input v-model="message"
            class="flex-grow w-0 px-4 py-2 rounded-xl bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none"
            type="text" placeholder="Message..." />
        <button type="submit" class="w-32 ml-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-semibold">
            Send
        </button>
    </form>
</template>
