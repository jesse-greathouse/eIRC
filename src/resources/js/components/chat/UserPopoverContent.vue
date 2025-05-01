<script setup lang="ts">
import { computed } from 'vue';
import { Link, router } from '@inertiajs/vue3';
import type { Profile } from '@/types';
import emitter from '@/lib/emitter';
import type { Channel } from '@/irc/models/Channel'
import type { Whois } from '@/irc/models/Whois';
import type { IrcClient } from '@/irc/IrcClient';

const { client, channel, whois, profile } = defineProps<{
    client: IrcClient,
    channel: Channel,
    whois: Whois;
    profile: Profile | null;
}>();

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const isSelf = computed(() => {
    return whois.nick == client.nick;
});

const isOp = computed(() => {
    return client?.isChannelOp(client.nick, channel?.name);
});

function openMessages() {
    const tabId = `pm-${whois.nick}`
    emit('switch-tab', tabId);
}

function goToProfile() {
    const realname = whois.realName || whois.nick;
    router.visit(`/profile/${realname}`);
}

function toggleOp() {
    const isCurrentlyOp = client?.isChannelOp(whois.nick, channel?.name) ?? false;
    const mode = isCurrentlyOp ? '-o' : '+o';
    client?.mode(whois.nick, mode, channel.name);
    emitter.emit('close-all-popovers');
}

function toggleVoice() {
    const isCurrentlyVoice = client?.isChannelVoice(whois.nick, channel?.name) ?? false;
    const mode = isCurrentlyVoice ? '-v' : '+v';
    client?.mode(whois.nick, mode, channel.name);
    emitter.emit('close-all-popovers');
}

function kick() {
    client?.kick(channel.name, whois.nick, `Kicked by ${client.nick}`);
    emitter.emit('close-all-popovers');
}

function ban() {
    // Construct a simple hostmask: nick!*@*
    const mask = `${whois.nick}!*@*`;
    client?.ban(channel.name, mask);
    emitter.emit('close-all-popovers');
}
</script>

<template>
    <div
        class="w-lg text-sm text-gray-900 bg-white border border-gray-200 rounded-lg dark:bg-gray-700 dark:border-gray-600 dark:text-white">
        <!-- Header Info -->
        <div class="px-4 py-2 border-b border-gray-200 dark:border-gray-600">
            <h3 class="font-semibold text-sm truncate">{{ whois.realName || whois.nick }}</h3>
            <p v-if="whois.user && whois.host" class="text-xs truncate">
                {{ whois.user }}@{{ whois.host }}
            </p>
        </div>

        <!-- Clickable List -->
        <Link v-if="isSelf" href="/settings"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white">
        Settings
        </Link>

        <a v-if="!isSelf" href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="openMessages">
            Messages
        </a>

        <a href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="goToProfile">
            Profile
        </a>

        <a v-if="!isSelf && isOp" href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="toggleOp">
            {{ client?.isChannelOp(whois.nick, channel?.name) ? 'Remove Op' : 'Give Op' }}
        </a>

        <a v-if="!isSelf && isOp" href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="toggleVoice">
            {{ client?.isChannelVoice(whois.nick, channel?.name) ? 'Remove Voice' : 'Give Voice' }}
        </a>

        <a v-if="!isSelf && isOp" href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="kick">
            Kick
        </a>

        <a v-if="!isSelf && isOp" href="#"
            class="block w-full px-4 py-2 border-b border-gray-200 cursor-pointer hover:bg-gray-100 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-600 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-500 dark:focus:text-white"
            @click.prevent="ban">
            Ban
        </a>

        <div class="px-4 py-2 border-b border-gray-200 dark:border-gray-600">
            <div class="w-full max-w-[400px]">
                <div v-if="profile?.bio" class="max-w-full text-xs break-words p-1" v-html="profile.bio">
                </div>
            </div>
        </div>
    </div>
</template>
