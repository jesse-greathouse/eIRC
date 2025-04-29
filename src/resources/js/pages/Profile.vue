<script setup lang="ts">
import { onMounted, computed, ref } from 'vue';
import { Head } from '@inertiajs/vue3';

import { type BreadcrumbItem, type Profile } from '@/types';
import type { User as IrcUser } from '@/irc/models/User';

import { getIrcClient } from '@/composables/useIrcClient';

import AppLayout from '@/layouts/AppLayout.vue';

interface Props {
    profile: Profile;
}

const props = defineProps<Props>();

// Breadcrumbs
const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Profile', href: `/profile/${props.profile.user?.realname}` },
];

// Client and ircUser computed binding
const client = ref<Awaited<ReturnType<typeof getIrcClient>> | null>(null);
const ircUser = ref<IrcUser | null>(null);;

// Soocial links
const hasSocialLinks = computed(() => {
    const links = [
        props.profile.x_link,
        props.profile.instagram_link,
        props.profile.tiktok_link,
        props.profile.youtube_link,
        props.profile.facebook_link,
        props.profile.pinterest_link,
    ];
    return links.some(link => !!link);
});

onMounted(async () => {
    client.value = await getIrcClient();
    monitorWhois(props.profile.user?.nick ?? '');
});

/**
 * Polls the IRC client for the user and triggers WHOIS if needed.
 * Stops after maxAttempts or when the user is found.
 */
function monitorWhois(nick: string) {
    let attempts = 0;
    const maxAttempts = 10;

    const interval = setInterval(() => {
        const foundUser = client.value?.getUser(nick) ?? null;

        if (foundUser) {
            ircUser.value = foundUser;

            if (!foundUser.whois.realName) {
                client.value?.whois(foundUser.nick);
            }

            clearInterval(interval);
        } else {
            attempts++;

            if (attempts >= maxAttempts) {
                console.warn(`[ABORT] Stopped waiting on whois after ${maxAttempts} attempts.`);
                clearInterval(interval);
            }
        }
    }, 500);
}
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">

        <Head :title="`${ircUser?.nick}'s Profile`" />

        <div class="flex flex-col space-y-10 p-4">
            <!-- User Name and Bio -->
            <div>
                <h1 class="text-2xl font-bold">{{ ircUser?.nick }}</h1>
                <p class="text-gray-600 dark:text-gray-400">{{ props.profile.bio }}</p>
            </div>

            <!-- Avatar and Basic Info -->
            <div class="flex items-center space-x-4">
                <img
                    v-if="props.profile.selected_avatar?.base64_data" :src="props.profile.selected_avatar.base64_data"
                    alt="Avatar" class="w-24 h-24 rounded-full border" />
                <div>
                    <p><strong>Nickname:</strong> {{ ircUser?.nick }}</p>
                    <p><strong>Timezone:</strong> {{ props.profile.timezone }}</p>
                </div>
            </div>

            <!-- Social Media Links -->
            <div v-if="hasSocialLinks">
                <h2 class="text-xl font-semibold mt-6">Social Links</h2>
                <ul class="list-disc list-inside text-blue-500">
                    <li v-if="props.profile.x_link"><a :href="props.profile.x_link" target="_blank">Twitter/X</a></li>
                    <li v-if="props.profile.instagram_link">
                        <a
                            :href="props.profile.instagram_link"
                            target="_blank">Instagram</a></li>
                    <li v-if="props.profile.tiktok_link"><a :href="props.profile.tiktok_link" target="_blank">TikTok</a>
                    </li>
                    <li v-if="props.profile.youtube_link">
                        <a
                            :href="props.profile.youtube_link"
                            target="_blank">YouTube</a></li>
                    <li v-if="props.profile.facebook_link">
                        <a
                            :href="props.profile.facebook_link"
                            target="_blank">Facebook</a></li>
                    <li v-if="props.profile.pinterest_link">
                        <a
                            :href="props.profile.pinterest_link"
                            target="_blank">Pinterest</a></li>
                </ul>
            </div>
        </div>
    </AppLayout>
</template>
