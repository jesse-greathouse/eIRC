<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem, type User } from '@/types';
import emitter from '@/lib/emitter';

import { useChatTabs } from '@/composables/useChatTabs';
import { useIrcLines } from '@/composables/useIrcLines';
import { useClient } from '@/composables/useClient';

import AppLayout from '@/layouts/AppLayout.vue';
import ContextMenu from '@/components/nav/ChatContextMenu.vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';

interface Props {
    user: User;
}

const props = defineProps<Props>();

// Breadcrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Chat', href: '/chat' },
];

const { coreApi } = useClient('core');

// Track favorites as bare channel names (no # handle)
const favorites = ref<string[]>(props.user.channels.split(','));

// Tab management
const activeTab = ref('console');
const { chatTabs, tabTargets, addChannelTab, addPrivmsgTab } = useChatTabs();
const currentTab = computed(() => chatTabs.value.find(t => t.id === activeTab.value));
const currentPane = computed(() => currentTab.value?.component ?? ConsolePane);

// Message buffer
const { lines } = useIrcLines();

onMounted(() => {
    emitter.on('joined-channel', addChannelTab);
    emitter.on('new-privmsg', addPrivmsgTab);
    emitter.on('switch-tab', switchTab);
    document.body.classList.add('overflow-hidden');
});

onBeforeUnmount(() => {
    emitter.off('joined-channel', addChannelTab);
    emitter.off('new-privmsg', addPrivmsgTab);
    emitter.off('switch-tab', switchTab);
    document.body.classList.remove('overflow-hidden');
});

// Watch and persist favorites to the server
watch(favorites, async (newFavorites) => {
    const validFavorites = newFavorites.filter(ch => typeof ch === 'string' && ch.trim() !== '');
    const uniqueFavorites = Array.from(new Set(validFavorites));

    try {
        await coreApi.updateUser(props.user.realname, {
            channels: uniqueFavorites,  // Send as array
        });
    } catch (err) {
        console.error('[Favorites] Save failed:', err);
    }
}, { deep: true });

function normalizeChannel(channel: string): string {
    return channel.replace(/^#/, '').trim().toLowerCase();
}

// Toggle favorite status
function toggleFavorite(channel: string) {
    const cleanedChannel = normalizeChannel(channel);

    const index = favorites.value.indexOf(cleanedChannel);
    if (index > -1) {
        favorites.value.splice(index, 1);
    } else {
        favorites.value.push(cleanedChannel);
    }
}

function switchTab(tabId: string) {
    if (!chatTabs.value.find(t => t.id === tabId)) {
        if (tabId.startsWith('pm-')) {
            const nick = tabId.replace(/^pm-/, '');
            addPrivmsgTab(nick);
        }
    }

    activeTab.value = tabId;

    nextTick(() => {
        const key = tabId.replace(/^pm-/, '');
        const elRef = tabTargets.get(key);
        if (elRef?.value) {
            elRef.value.scrollIntoView({ behavior: 'smooth' });
        }
    });
}
</script>

<template>

    <Head title="Chat" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-1 min-h-0 overflow-hidden w-full gap-4">
            <!-- Sidebar -->
            <aside
                class="flex flex-col h-full w-64 shrink-0 rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-white dark:bg-gray-800 overflow-hidden">
                <ContextMenu :tabs="chatTabs" :active-tab="activeTab" @update-tab="switchTab">
                    <!-- Slot to render tabs with star buttons -->
                    <template #tab="{ tab }">
                        <div class="flex justify-between items-center w-full">
                            <span>{{ tab.label }}</span>
                            <button
                                v-if="tab.id.startsWith('channel-')"
                                @click.stop="toggleFavorite(tab.id.replace(/^channel-/, ''))">
                                <!-- Filled Star if Favorite -->
                                <svg
                                    v-if="favorites.includes(normalizeChannel(tab.id.replace(/^channel-/, '')))"
                                    xmlns="http://www.w3.org/2000/svg" fill="yellow" viewBox="0 0 24 24"
                                    stroke="currentColor" class="w-4 h-4">
                                    <path
                                        stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.36 4.192a1 1 0 00.95.69h4.404c.969 0 1.371 1.24.588 1.81l-3.57 2.593a1 1 0 00-.364 1.118l1.36 4.192c.3.921-.755 1.688-1.538 1.118L12 15.347l-3.57 2.593c-.783.57-1.838-.197-1.538-1.118l1.36-4.192a1 1 0 00-.364-1.118L4.318 9.619c-.783-.57-.38-1.81.588-1.81h4.404a1 1 0 00.95-.69l1.36-4.192z" />
                                </svg>
                                <!-- Empty Star if Not Favorite -->
                                <svg
                                    v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke="currentColor" class="w-4 h-4">
                                    <path
                                        stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.36 4.192a1 1 0 00.95.69h4.404c.969 0 1.371 1.24.588 1.81l-3.57 2.593a1 1 0 00-.364 1.118l1.36 4.192c.3.921-.755 1.688-1.538 1.118L12 15.347l-3.57 2.593c-.783.57-1.838-.197-1.538-1.118l1.36-4.192a1 1 0 00-.364-1.118L4.318 9.619c-.783-.57-.38-1.81.588-1.81h4.404a1 1 0 00.95-.69l1.36-4.192z" />
                                </svg>
                            </button>
                        </div>
                    </template>
                </ContextMenu>
            </aside>

            <!-- Chat Pane -->
            <div
                class="flex-1 flex flex-col min-h-0 overflow-hidden rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-gray-100 dark:bg-gray-900">
                <component :is="currentPane" :lines="lines" :tab-id="activeTab" @switch-tab="switchTab" />
            </div>
        </div>
    </AppLayout>
</template>
