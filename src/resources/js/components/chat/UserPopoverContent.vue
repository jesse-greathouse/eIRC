<script setup lang="ts">
import type { Profile } from '@/types';
import { router } from '@inertiajs/vue3'
import type { Whois } from '@/irc/models/Whois';

const { whois, profile } = defineProps<{
    whois: Whois;
    profile: Profile | null;
}>();

function goToProfile() {
    const realname = whois.realName || whois.nick;
    router.visit(`/profile/${realname}`);
}

function openSettings() {
    console.log('Opening settings for:', whois.nick);
    // TODO: Make this ignore/block
}

function openMessages() {
    console.log('Opening messages with:', whois.nick);
    // TODO: Opens a private message chat with user
}

function startDownload() {
    console.log('Downloading info for:', whois.nick);
    // TODO: change this functionality
}
</script>

<template>
    <div
        class="w-full text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-lg dark:bg-gray-700 dark:border-gray-600 dark:text-white">
        <!-- Header Info -->
        <div class="px-4 py-2 border-b border-gray-200 dark:border-gray-600">
            <h3 class="font-semibold text-sm truncate">{{ whois.realName || whois.nick }}</h3>
            <p v-if="whois.user && whois.host" class="text-xs truncate">
                {{ whois.user }}@{{ whois.host }}
            </p>
            <p v-if="profile?.bio" class="text-xs text-gray-400 dark:text-gray-300 mt-1 truncate">
                {{ profile.bio }}
            </p>
        </div>

        <!-- Clickable List -->
        <a href="#" @click.prevent="goToProfile"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white">
            Profile
        </a>
        <a href="#" @click.prevent="openSettings"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white">
            Settings
        </a>
        <a href="#" @click.prevent="openMessages"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white">
            Messages
        </a>
        <a href="#" @click.prevent="startDownload"
            class="block w-full px-4 py-2 rounded-b-lg cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white">
            Download
        </a>
    </div>
</template>
