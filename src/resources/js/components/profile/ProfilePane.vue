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
    return cleaned.length > 17 ? cleaned.slice(0, 17) + '...' : cleaned;
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

                <!-- Status Dot + Away Badge -->
                <div class="absolute left-16 bottom-0 flex">
                    <span
                        v-if="props.ircUser" class="w-4 h-4 border-2 border-white dark:border-gray-800 rounded-full"
                        :class="{
                            'bg-gray-300': isAway,
                            'bg-green-400': !isAway
                        }"></span>
                    <span
                        v-if="isAway"
                        class="ml-1.5 bg-gray-100 text-gray-800 text-xs font-medium px-2.5 py-0.5 rounded-sm dark:bg-gray-700 dark:text-gray-400 border border-gray-500 whitespace-nowrap">
                        {{ awayMessage }}
                    </span>
                </div>
            </div>

            <h1 class="text-3xl font-bold">{{ props.ircUser?.nick }}</h1>

            <div class="max-w-full overflow-hidden flex justify-center">
                <div class="w-full aspect-square">
                    <p
                        v-if="props.profile.bio"
                        class="text-xs text-gray-400 dark:text-gray-300 w-full h-full overflow-hidden text-ellipsis break-words p-2"
                        v-html="props.profile.bio">
                    </p>
                </div>
            </div>
        </div>

        <!-- Social Icons Row -->
        <div class="flex justify-center gap-4 flex-wrap text-gray-500 dark:text-gray-400">
            <a v-if="props.profile.x_link" :href="props.profile.x_link" target="_blank" aria-label="Twitter/X">
                <svg class="w-5 h-5 hover:text-blue-500" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M22 4.01c-.77.34-1.6.56-2.47.66a4.3 4.3 0 0 0 1.88-2.38 8.67 8.67 0 0 1-2.72 1.04A4.29 4.29 0 0 0 16.07 3c-2.4 0-4.34 1.95-4.34 4.34 0 .34.04.67.11.99-3.6-.18-6.8-1.9-8.94-4.5a4.34 4.34 0 0 0 1.34 5.78 4.25 4.25 0 0 1-1.96-.54v.05c0 2.03 1.44 3.72 3.34 4.1-.35.1-.72.15-1.1.15-.27 0-.53-.03-.78-.08.53 1.66 2.07 2.87 3.9 2.91a8.61 8.61 0 0 1-5.33 1.84c-.35 0-.7-.02-1.04-.06A12.17 12.17 0 0 0 8.29 21c7.56 0 11.7-6.26 11.7-11.7l-.01-.53A8.4 8.4 0 0 0 22 4.01Z" />
                </svg>
            </a>
            <a
                v-if="props.profile.instagram_link" :href="props.profile.instagram_link" target="_blank"
                aria-label="Instagram">
                <svg class="w-5 h-5 hover:text-pink-500" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M7.75 2A5.75 5.75 0 0 0 2 7.75v8.5A5.75 5.75 0 0 0 7.75 22h8.5A5.75 5.75 0 0 0 22 16.25v-8.5A5.75 5.75 0 0 0 16.25 2h-8.5Zm0 1.5h8.5A4.25 4.25 0 0 1 20.5 7.75v8.5a4.25 4.25 0 0 1-4.25 4.25h-8.5A4.25 4.25 0 0 1 3.5 16.25v-8.5A4.25 4.25 0 0 1 7.75 3.5Zm8.75 2a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5ZM12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm0 1.5a3.5 3.5 0 1 1 0 7 3.5 3.5 0 0 1 0-7Z" />
                </svg>
            </a>
            <a v-if="props.profile.tiktok_link" :href="props.profile.tiktok_link" target="_blank" aria-label="TikTok">
                <svg class="w-5 h-5 hover:text-fuchsia-600" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M9 3a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1c0 3.31 2.69 6 6 6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1 9 9 0 1 1-9-9Z" />
                </svg>
            </a>
            <a
                v-if="props.profile.youtube_link" :href="props.profile.youtube_link" target="_blank"
                aria-label="YouTube">
                <svg class="w-5 h-5 hover:text-red-600" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M10 15.5v-7l6 3.5-6 3.5Zm11.5-8.25a3.1 3.1 0 0 0-2.2-2.2C17.6 4.5 12 4.5 12 4.5s-5.6 0-7.3.55a3.1 3.1 0 0 0-2.2 2.2C2 9.25 2 12 2 12s0 2.75.5 5.25a3.1 3.1 0 0 0 2.2 2.2c1.7.55 7.3.55 7.3.55s5.6 0 7.3-.55a3.1 3.1 0 0 0 2.2-2.2c.5-2.5.5-5.25.5-5.25s0-2.75-.5-5.25Z" />
                </svg>
            </a>
            <a
                v-if="props.profile.facebook_link" :href="props.profile.facebook_link" target="_blank"
                aria-label="Facebook">
                <svg class="w-5 h-5 hover:text-blue-600" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M13 10h5.5a1 1 0 0 1 .99 1.14 8 8 0 1 1-6.37-6.37A1 1 0 0 1 14.5 5.5V8a1 1 0 0 1-1 1h-1a3 3 0 1 0 0 6h1a1 1 0 0 1 1 1v2.5a1 1 0 0 1-1.15.99A8 8 0 0 1 13 10Z" />
                </svg>
            </a>
            <a
                v-if="props.profile.pinterest_link" :href="props.profile.pinterest_link" target="_blank"
                aria-label="Pinterest">
                <svg class="w-5 h-5 hover:text-red-500" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M8.85 21.94c.3.1.6-.1.7-.3.3-1 .9-3.3 1.1-4.3.2-.6.3-.8.6-1.3.3.6 1.2 1.1 2.1 1.1 2.8 0 4.9-2.6 4.9-6.1 0-2.6-2.2-5-5.7-5-4.3 0-6.6 3.1-6.6 5.9 0 1.3.5 2.4 1.6 2.8.2.1.3 0 .4-.2l.2-.8c.1-.3.1-.4 0-.7-.2-.5-.4-1-.4-1.6 0-2.3 1.7-4.4 4.6-4.4 2.5 0 4.2 1.7 4.2 4.2 0 2.7-1.4 4.4-3.3 4.4-.8 0-1.5-.7-1.3-1.6.2-.7.5-1.5.5-2 0-.5-.2-1-1-1-.8 0-1.5.9-1.5 2.1 0 .8.3 1.3.3 1.3s-1 4.2-1.2 5c-.2.8.2.9.4 1Z" />
                </svg>
            </a>
        </div>
    </div>
</template>
