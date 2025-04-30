<script setup lang="ts">
import { cn } from '@/lib/utils'; // Assuming you have a cn() helper to merge classes

const props = defineProps<{
    modelValue?: string;
    placeholder?: string;
    id?: string;
    class?: string;
}>();

const emit = defineEmits<{
    (e: 'update:modelValue', value: string): void;
}>();

function onInput(event: Event) {
    const target = event.target as HTMLTextAreaElement;
    emit('update:modelValue', target.value);
}
</script>

<template>
    <textarea :id="id" :placeholder="placeholder" :value="modelValue" @input="onInput" :class="cn(
        'flex min-h-[6rem] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 resize-none',
        props.class
    )" />
</template>
