<script setup lang="ts">
import { type BreadcrumbItem } from '@/types';
import type { ChatTab } from '@/types/chat';

import AppLayout from '@/layouts/AppLayout.vue';
import PlaceholderPattern from '../components/PlaceholderPattern.vue';
import ContextMenu from '@/components/nav/ChatContextMenu.vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';
import ChannelPane from '@/components/chat/ChannelPane.vue';
import PrivmsgPane from '@/components/chat/PrivmsgPane.vue';
import { useChannelTabs } from '@/composables/useChannelTabs';
import { usePrivmsgTabs } from '@/composables/usePrivmsgTabs';

import { ref, computed, onMounted, nextTick } from 'vue';
import { Head } from '@inertiajs/vue3';

const { channels, addChannel } = useChannelTabs();
const { privmsgs, addPrivmsgUser } = usePrivmsgTabs();

function trackRef(id: string) {
    const key = id.replace(/^channel-/, '').replace(/^pm-/, '');
    if (!tabTargets.has(key)) {
        tabTargets.set(key, ref<HTMLElement | null>(null));
    }
}

function addDynamicChannel(name: string) {
    trackRef(`channel-${name}`);
    addChannel(name);
}

function addDynamicPrivmsg(nick: string) {
    trackRef(`pm-${nick}`);
    addPrivmsgUser(nick);
}

defineProps<{
    chat_token: string;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Chat', href: '/chat' },
];

const tabTriggers = {
    console: { id: 'console', label: 'Console' },
    ...channels.value,
    ...privmsgs.value,
};

// Tab targets will be created and removed on demand.
const tabTargets = new Map<string, Ref<HTMLElement | null>>();

const consoleTab: ChatTab = {
    id: 'console',
    label: 'Console',
    component: ConsolePane,
};

const chatTabs = computed<ChatTab[]>(() => [
    consoleTab,
    ...channels.value.map(name => ({
        id: `channel-${name}`,
        label: `#${name}`,
        component: ChannelPane,
    })),
    ...privmsgs.value.map(nick => ({
        id: `pm-${nick}`,
        label: `Private: ${nick}`,
        component: PrivmsgPane,
    })),
]);

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

const currentTab = computed(() => chatTabs.value.find(tab => tab.id === activeTab.value));
const CurrentPane = computed(() => currentTab.value?.component ?? ConsolePane);
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
                <component :is="CurrentPane" />
            </div>
        </div>
    </AppLayout>
</template>
