<script setup lang="ts">
import { shallowRef, watchEffect, ref, nextTick, watch } from 'vue';
import type { IrcLine } from '@/types/IrcLine';
import { IrcClient } from '@/irc/IrcClient';

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
    client: IrcClient;
}>();

const tabLines = shallowRef<IrcLine[]>([]);
const scrollContainer = ref<HTMLElement | null>(null);

watchEffect(() => {
    tabLines.value = props.lines.get(props.tabId) ?? [];
});

watch(tabLines, async () => {
    await nextTick();
    scrollContainer.value?.scrollTo({
        top: scrollContainer.value.scrollHeight,
        behavior: 'smooth',
    });
});

defineExpose({ tabLines, scrollContainer });
</script>

<template>
    <div class="flex flex-col flex-1 min-h-0 overflow-hidden">
        <!-- Scrollable message buffer -->
        <div class="flex-1 min-h-0 overflow-y-auto px-4 pt-4 space-y-1" ref="scrollContainer">
            <h2 class="text-lg font-semibold mb-2">{{ props.tabId }}</h2>
            <slot :tabLines="tabLines" :client="props.client" />
        </div>

        <!-- Docked input -->
        <div class="shrink-0 p-4 border-t border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800">
            <slot name="input" :client="props.client" />
        </div>
    </div>
</template>
