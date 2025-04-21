<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem } from '@/types';
import emitter from '@/lib/emitter';

import AppLayout from '@/layouts/AppLayout.vue';
import ContextMenu from '@/components/nav/ChatContextMenu.vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';

import { useChatTabs } from '@/composables/useChatTabs';
import { getIrcClient } from '@/composables/useIrcClient';
import { useIrcLines } from '@/composables/useIrcLines';

const { } = defineProps<{}>();

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
const { lines } = useIrcLines();
const ircClient = getIrcClient();

onMounted(() => {
    emitter.on('joined-channel', addChannelTab);
    emitter.on('new-privmsg', addPrivmsgTab);
    emitter.on('switch-tab', switchTab);
    document.body.classList.add('overflow-hidden');

    if (ircClient) {
        ircClient.channels(); // Ask the client for channel membership info
    } else {
        console.warn('[Chat.vue] IRC client not initialized');
    }
});

onBeforeUnmount(() => {
    emitter.off('joined-channel', addChannelTab);
    emitter.off('new-privmsg', addPrivmsgTab);
    emitter.off('switch-tab', switchTab);
    document.body.classList.remove('overflow-hidden');
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
                <component :is="currentPane" :lines="lines" :tab-id="activeTab" @switch-tab="switchTab" />
            </div>
        </div>
    </AppLayout>
</template>
