<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem } from '@/types';
import { parseIrcLine } from '@/lib/parseIrcLine';
import { getTabKey } from '@/lib/getTabKey';

import AppLayout from '@/layouts/AppLayout.vue';
import ContextMenu from '@/components/nav/ChatContextMenu.vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';

import { useChatTabs } from '@/composables/useChatTabs';
import { useWebSocket } from '@/composables/useWebSocket';
import { useIrcLines } from '@/composables/useIrcLines';

import { IrcClient } from '@/irc/IrcClient';
import { buildHandlers } from '@/irc/buildHandlers';

const { chat_token } = defineProps<{ chat_token: string }>();

// Breadcrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Chat', href: '/chat' },
];

// Tab management
const activeTab = ref('console');
const { chatTabs, tabTargets, addChannelTab, addPrivmsgTab } = useChatTabs();
const currentTab = computed(() => chatTabs.value.find(t => t.id === activeTab.value));
const currentPane = computed(() => currentTab.value?.component ?? ConsolePane);

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

// IRC Client and Message buffer dispatch
const { lines, addLinesTo, getLinesFor, addUserLineTo } = useIrcLines();

const ircClient = new IrcClient(
    (msg) => console.log(`[IRC] ${msg}`),
    (line) => {
        const target = getTabKey(line);
        addLinesTo(target, [line]);
    },
    {
        onJoinChannel: (channel) => {
            addChannelTab(channel);
        },
        onPrivmsg: (nick) => {
            addPrivmsgTab(nick);
        },
        addUserLineTo, // 💡 hook passed here
    }
);

// Register handlers
Object.entries(buildHandlers()).forEach(([event, handlers]) => {
    handlers.forEach(h => ircClient.addEventHandler(event, h));
});

// WebSocket connection
const { connect, send, disconnect } = useWebSocket(
    `ws://${location.hostname}:9667/?chat_token=${chat_token}`,
    (rawLine) => {
        const parsed = parseIrcLine(rawLine);
        ircClient.handleLine(parsed);
    }
);

function sendIrcCommand(rawCommand: string) {
    const message = `/input ${rawCommand}`;
    send(message);
}


onMounted(() => {
    // Overflow-hidden on the body so the chat pane can grow with the view pane
    document.body.classList.add('overflow-hidden');

    // connecting to the websocket initiates the connection to the IRC Server.
    connect();
});

onBeforeUnmount(() => {
    document.body.classList.remove('overflow-hidden');
    disconnect();
});
</script>

<template>

    <Head title="Chat" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-1 min-h-0 overflow-hidden w-full gap-4">
            <!-- Sidebar -->
            <aside
                class="flex flex-col h-full w-64 shrink-0 rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-white dark:bg-gray-800 overflow-hidden">
                <ContextMenu :tabs="chatTabs" :activeTab="activeTab" @update-tab="switchTab" />
            </aside>

            <!-- Chat Pane -->
            <div
                class="flex-1 flex flex-col min-h-0 overflow-hidden rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-gray-100 dark:bg-gray-900">
                <component :is="currentPane" :lines="lines" :tab-id="activeTab" :send-irc-command="sendIrcCommand" />
            </div>
        </div>
    </AppLayout>
</template>
