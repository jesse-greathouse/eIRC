<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem, type Profile } from '@/types';
import type { User as IrcUser } from '@/irc/models/User';
import type { Channel } from '@/irc/models/Channel';

import AppLayout from '@/layouts/AppLayout.vue';
import ProfileContextMenu from '@/components/nav/ProfileContextMenu.vue';
import ProfilePane from '@/components/profile/ProfilePane.vue';
import { getIrcClient } from '@/composables/useIrcClient';

interface Props {
    profile: Profile;
}

const props = defineProps<Props>();

// WhoisInterval for polling User Whois in chat.
let whoisInterval: ReturnType<typeof setInterval> | null = null;

// Breadcrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Profile', href: `/profile/${props.profile.user?.realname}` },
];

// Client and ircUser computed binding
const client = ref<Awaited<ReturnType<typeof getIrcClient>> | null>(null);
const ircUser = ref<IrcUser | null>(null);
const channels = ref<Channel[]>([]);

onMounted(async () => {
    const nick = props.profile.user?.nick ?? '';
    client.value = await getIrcClient();
    ircUser.value = client.value.getUser(nick);
    channels.value = ircUser.value ? Array.from(ircUser.value.channels) : [];
    monitorWhois(nick);
});

onBeforeUnmount(() => {
    if (whoisInterval) {
        clearInterval(whoisInterval);
        whoisInterval = null;
    }
});

// This will eventually handle clicked channel buttons
function switchTab(tabId: string) {
    console.log('Switch to channel:', tabId);
}

async function monitorWhois(nick: string) {
    async function waitUntilReady() {
        const maxAttempts = 100; // 10s max
        let attempts = 0;

        while ((!client.value || !client.value.isReady()) && attempts < maxAttempts) {
            await new Promise((resolve) => setTimeout(resolve, 100));
            attempts++;
        }

        if (!client.value || !client.value.isReady()) {
            console.warn('[WARN] Client not ready after waiting.');
            return false;
        }

        return true;
    }

    async function doWhoisRefresh() {
        const ready = await waitUntilReady();
        if (!ready) return;

        client.value!.whois(nick);

        setTimeout(() => {
            if (!client.value || !client.value.isReady()) return;

            ircUser.value = client.value.getUser(nick) ?? null;
            channels.value = ircUser.value ? Array.from(ircUser.value.channels) : [];

        }, 500);
    }

    // Start initial WHOIS immediately
    await doWhoisRefresh();

    // Repeat every 30 seconds
    whoisInterval = setInterval(doWhoisRefresh, 30000);
}
</script>

<template>

    <Head :title="`${ircUser?.nick}'s Profile`" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-1 min-h-0 overflow-hidden w-full gap-4">
            <!-- Sidebar -->
            <aside
                class="flex flex-col h-full w-64 shrink-0 rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-white dark:bg-gray-800 overflow-hidden">
                <ProfileContextMenu :channels="channels" @switch-tab="switchTab" />
            </aside>

            <!-- Main Profile Pane -->
            <ProfilePane :irc-user="ircUser" :profile="props.profile" />
        </div>
    </AppLayout>
</template>
