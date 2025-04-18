<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem } from '@/types';
import type { ChatTab } from '@/types/chat';
import { parseIrcLine } from '@/lib/parseIrcLine';
import { getTabKey } from '@/lib/getTabKey';
import AppLayout from '@/layouts/AppLayout.vue';
import ContextMenu from '@/components/nav/ChatContextMenu.vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';
import ChannelPane from '@/components/chat/ChannelPane.vue';
import PrivmsgPane from '@/components/chat/PrivmsgPane.vue';
import { useChatTabs } from '@/composables/useChatTabs';
import { useWebSocket } from '@/composables/useWebSocket';
import { useIrcLines } from '@/composables/useIrcLines';

function getTabKey(line: IrcLine): string {
    try {
        if (line.command === 'PRIVMSG' && line.params[0]?.startsWith('#')) {
            return `channel-${line.params[0]}`;
        } else if (line.command === 'PRIVMSG') {
            return `pm-${line.prefix?.split('!')[0] || 'unknown'}`;
        }
    } catch (e) {
        console.error('[getTabKey] failed for line:', line, e);
    }
    return 'console';
}

const { chat_token } = defineProps<{
    chat_token: string;
}>();

// Set up BreadCrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Chat', href: '/chat' },
];

// Set up Tabs
const { chatTabs, tabTargets } = useChatTabs();
const activeTab = ref('console');
function switchTab(tabId: string) {
    activeTab.value = tabId;

    nextTick(() => {
        const key = tabId.replace(/^channel-/, '').replace(/^pm-/, '');
        const elRef = tabTargets.get(key);
        if (elRef?.value) {
            elRef.value.scrollIntoView({ behavior: 'smooth' });
        }
    });
}
const currentPane = computed(() => {
    const tab = chatTabs.value.find(t => t.id === activeTab.value);
    return tab?.component ?? ConsolePane;
});

// Set up Websocket i/o
const { lines, addLinesTo } = useIrcLines();
const { connect, send, disconnect } = useWebSocket(
    `ws://${location.hostname}:9667/?chat_token=${chat_token}`,
    (rawLine) => {
        const parsed = parseIrcLine(rawLine);
        const target = getTabKey(parsed);
        console.log(parsed.toObject());
        addLinesTo(target, [parsed]);
    }
);

onMounted(connect);
onBeforeUnmount(disconnect);

</script>

<template>

    <Head title="Chat" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex w-full flex-1 min-h-0 gap-4">
            <!-- Context Menu -->
            <aside
                class="w-64 shrink-0 h-full rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-white dark:bg-gray-800 p-4">
                <ContextMenu :tabs="chatTabs" :activeTab="activeTab" @update-tab="switchTab" />
            </aside>

            <!-- Main Chat Pane -->
            <div class="flex-1 flex flex-col h-full min-h-0 overflow-hidden">
                <component :is="currentPane" :lines="lines" />
            </div>
        </div>
    </AppLayout>
</template>
