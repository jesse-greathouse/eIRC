<script setup lang="ts">
import { ref, computed, reactive, onMounted, onBeforeUnmount, nextTick } from 'vue';
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

import { IrcClient } from '@/irc/IrcClient';
import { buildHandlers } from '@/irc/buildHandlers';

function registerComponentForTab(id: string, component: any) {
    tabComponentMap[id] = component;
}

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

const { chat_token } = defineProps<{ chat_token: string }>();

const activeTab = ref('console');

const tabComponentMap = reactive<Record<string, any>>({
    console: ConsolePane,
});

// Breadcrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Chat', href: '/chat' },
];

// Tab management
const { chatTabs, tabTargets, addChannelTab, addPrivmsgTab } = useChatTabs();

const currentTab = computed(() => chatTabs.value.find(t => t.id === activeTab.value));
const currentPane = computed(() => tabComponentMap[activeTab.value] ?? ConsolePane);

// IRC message buffer
const { lines, addLinesTo, getLinesFor } = useIrcLines();

const ircClient = new IrcClient(
    (msg) => console.log(`[IRC] ${msg}`),
    (line) => {
        const target = getTabKey(line);
        addLinesTo(target, [line]);
    },
    {
        onJoinChannel: (channel) => {
            const id = `channel-${channel}`;
            addChannelTab(channel);
            registerComponentForTab(id, ChannelPane);
        },
        onPrivmsg: (nick) => {
            const id = `pm-${nick}`;
            addPrivmsgTab(nick);
            registerComponentForTab(id, PrivmsgPane);
        },
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
                <component :is="currentPane" :lines="lines" :tab-id="activeTab" />
            </div>
        </div>
    </AppLayout>
</template>
