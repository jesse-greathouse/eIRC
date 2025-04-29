<script setup lang="ts">
import { computed } from 'vue';
import type { Profile } from '@/types';
import type { User as IrcUser } from '@/irc/models/User';

const props = defineProps<{
    ircUser: IrcUser | null;
    profile: Profile;
}>();

// Computed away status
const isAway = computed(() => props.ircUser?.whois?.away ?? false);

// Computed normalized away message
const awayMessage = computed(() => {
    const raw = props.ircUser?.whois?.awayMessage ?? '';

    if (!raw) return '...';

    const cleaned = raw.trim().replace(/[^\w.\-\s]/g, '');

    if (cleaned.length > 17) {
        return cleaned.slice(0, 17) + '...';
    }

    return cleaned;
});
</script>

<template>
    <div
        class="flex-1 flex flex-col min-h-0 overflow-hidden rounded-xl border border-sidebar-border/70 dark:border-sidebar-border bg-gray-100 dark:bg-gray-900 p-6 space-y-10">

        <!-- Profile Header -->
        <div class="flex flex-col items-center space-y-4 relative">
            <div class="relative">
                <img
                    v-if="props.profile.selected_avatar?.base64_data" :src="props.profile.selected_avatar.base64_data"
                    alt="Avatar" class="w-24 h-24 rounded-full border" />

                <!-- Status Dot + Away Badge container -->
                <div class="absolute  left-16 bottom-0 flex">
                    <!-- Away/Online Dot -->
                    <span
                        v-if="props.ircUser" class="w-4 h-4 border-2 border-white dark:border-gray-800 rounded-full"
                        :class="{
                            'bg-gray-300': isAway,
                            'bg-green-400': !isAway,
                        }"></span>

                    <!-- Away Message Badge -->
                    <span
                        v-if="isAway"
                        class="ml-1.5 bg-gray-100 text-gray-800 text-xs font-medium px-2.5 py-0.5 rounded-sm dark:bg-gray-700 dark:text-gray-400 border border-gray-500 whitespace-nowrap">
                        {{ awayMessage }}
                    </span>
                </div>
            </div>

            <h1 class="text-3xl font-bold">{{ props.ircUser?.nick }}</h1>
            <p class="text-gray-600 dark:text-gray-400 text-center">{{ props.profile.bio }}</p>
        </div>

        <!-- Details -->
        <div class="flex flex-col space-y-6 mt-6">
            <div>
                <h2 class="text-xl font-semibold">Details</h2>
                <p><strong>Timezone:</strong> {{ props.profile.timezone }}</p>
            </div>

            <div
                v-if="props.profile.x_link || props.profile.instagram_link || props.profile.tiktok_link || props.profile.youtube_link || props.profile.facebook_link || props.profile.pinterest_link">
                <h2 class="text-xl font-semibold">Social Links</h2>
                <ul class="list-disc list-inside text-blue-500">
                    <li v-if="props.profile.x_link">
                        <a :href="props.profile.x_link" target="_blank">Twitter/X</a>
                    </li>
                    <li v-if="props.profile.instagram_link">
                        <a :href="props.profile.instagram_link" target="_blank">Instagram</a>
                    </li>
                    <li v-if="props.profile.tiktok_link">
                        <a :href="props.profile.tiktok_link" target="_blank">TikTok</a>
                    </li>
                    <li v-if="props.profile.youtube_link">
                        <a :href="props.profile.youtube_link" target="_blank">YouTube</a>
                    </li>
                    <li v-if="props.profile.facebook_link">
                        <a :href="props.profile.facebook_link" target="_blank">Facebook</a>
                    </li>
                    <li v-if="props.profile.pinterest_link">
                        <a :href="props.profile.pinterest_link" target="_blank">Pinterest</a>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</template>
