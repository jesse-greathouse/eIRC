<script setup lang="ts">
import { shallowRef, watchEffect, ref, nextTick, onMounted } from 'vue';
import type { IrcLine } from '@/types/IrcLine';

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
}>();

const tabLines = shallowRef<IrcLine[]>([]); // shallow reactivity

watchEffect(() => {
    tabLines.value = props.lines.get(props.tabId) ?? [];
});

const container = ref<HTMLElement | null>(null);

onMounted(() => {
    //console.log(tabLines);
});

// Auto-scroll when new lines are added
watch(tabLines, async () => {
    await nextTick();
    container.value?.scrollTo({
        top: container.value.scrollHeight,
        behavior: 'smooth',
    });
});
</script>

<template>
    <div ref="container"
        class="flex-1 flex flex-col min-h-0 overflow-y-auto rounded-xl border border-sidebar-border/70 dark:border-sidebar-border p-4 bg-gray-100 dark:bg-gray-900">
        <h2 class="text-lg font-semibold mb-2">{{ props.tabId }}</h2>

        <ul class="text-sm text-gray-700 dark:text-gray-300 space-y-1">
            <li v-for="(line, index) in tabLines" :key="line.id ?? index">
                [{{ line.command }}] {{ line.raw }}
            </li>
        </ul>
    </div>
</template>
