<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount, computed, nextTick } from 'vue';
import type { User as IrcUser } from '@/irc/models/User';
import type { Channel } from '@/irc/models/Channel'
import type { Whois } from '@/irc/models/Whois'
import type { IrcClient } from '@/irc/IrcClient';
import type { Profile } from '@/types';
import emitter from '@/lib/emitter';
import { useProfiles } from '@/composables/useProfiles';
import { getIrcClient } from '@/composables/useIrcClient';
import UserPopoverContent from '@/components/chat/UserPopoverContent.vue';

interface Props {
    user: IrcUser;
    channel: Channel;
}

const props = defineProps<Props>();

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

// State objects
const client = ref<IrcClient | null>(null);
const ircUser = ref<IrcUser>(props.user);
const profile = ref<Profile | null>(null);
const whois = ref<Whois | null>(null);
const popoverRef = ref<HTMLElement | null>(null);

// User Context Popover
const popoverVisible = ref(false);
const popoverId = `popover-${props.user.nick}`;
const popoverPosition = ref({ top: 0, left: 0 });

// User state handling
const modeTick = ref(0);
const isAway = ref(false);
const awayMessage = ref('...');
const isOp = computed(() => {
    void modeTick.value; // depend on tick
    return client?.value?.isChannelOp(props.user.nick, props.channel?.name);
});
const isVoice = computed(() => {
    void modeTick.value; // depend on tick
    return client?.value?.isChannelVoice(props.user.nick, props.channel?.name);
});

// Avatar URL directly from profile
const avatarUrl = computed(() => {
    return profile.value?.selected_avatar?.base64_data || '/avatar-placeholder.png';
});

// Nick straight from ircUser
const nick = computed(() => ircUser.value.nick);

onMounted(async () => {
    client.value = await getIrcClient();
    initialize();

    // close all popovers event handler.
    emitter.on('close-all-popovers', () => {
        popoverVisible.value = false;
    });

    emitter.on('mode-change', ({ nick, channel }) => {
        if (nick === props.user.nick && channel === props.channel?.name) {
            modeTick.value++; // triggers recomputation of isOp and isVoice
        }
    });
});

onBeforeUnmount(() => {
    emitter.off('close-all-popovers');
    emitter.off('mode-change');
});

watch(
    props.user.whois,
    async (newWhois, oldWhois) => {
        if (!newWhois) {
            return;
        }

        await nextTick();

        whois.value = newWhois
        isAway.value = newWhois?.away ?? false;

        awayMessage.value = normalizeAwayMessage(newWhois.awayMessage);

        // Update profile if realName changes
        if (newWhois.realName && newWhois.realName !== oldWhois?.realName) {
            await loadProfile(newWhois.realName);
        }
    },
    { immediate: true }
);

// Watch for full user replacement
watch(() => props.user, (newUser) => {
    ircUser.value = newUser;
    whois.value = newUser.whois
    initialize();
});

// Load profile based on whois.realName
const { getProfile } = useProfiles();

async function loadProfile(realname: string) {
    const fetchedProfile = await getProfile(realname);
    profile.value = fetchedProfile || null;
}

// Inside initialize:
async function initialize() {
    if (!ircUser.value.whois || !ircUser.value.whois.realName) {
        await client.value?.whois(ircUser.value.nick);
        await new Promise(resolve => setTimeout(resolve, 300));
    }
    await loadProfile(ircUser.value.whois?.realName || ircUser.value.nick);
    isAway.value = ircUser.value.whois?.away ?? false;
    awayMessage.value = normalizeAwayMessage(ircUser.value.whois?.awayMessage);
}

// Left-click to open privmsg tab
function handleLeftClick() {
    client?.value?.whois(props.user.nick);
    emit('switch-tab', `pm-${props.user.nick}`);
}

let fadeOutTimer: ReturnType<typeof setTimeout> | null = null;

// Right-click to toggle popover and position it with top-right corner at cursor
async function handleRightClick(event: MouseEvent) {
    event.preventDefault();
    emitter.emit('close-all-popovers');

    const popoverWidth = 512; // Tailwind w-lg
    const padding = 10;
    const offsetX = 4;
    const offsetY = 8;

    let left = event.clientX + offsetX;
    let top = event.clientY + offsetY;

    // Clamp right
    if (left + popoverWidth > window.innerWidth - padding) {
        left = window.innerWidth - popoverWidth - padding;
    }
    if (left < padding) {
        left = padding;
    }

    popoverPosition.value = { top, left };
    popoverVisible.value = true;

    if (fadeOutTimer) clearTimeout(fadeOutTimer);

    await nextTick();

    // Now we can safely measure actual height
    const popoverEl = popoverRef.value;
    if (popoverEl) {
        const rect = popoverEl.getBoundingClientRect();
        const actualHeight = rect.height;

        if (top + actualHeight > window.innerHeight - padding) {
            top = window.innerHeight - actualHeight - padding;
            if (top < padding) top = padding;
            popoverPosition.value.top = top;
        }
    }
}

// Handle fade out after leaving popover
function onPopoverMouseLeave() {
    fadeOutTimer = setTimeout(() => {
        popoverVisible.value = false;
    }, 200);
}

function onPopoverMouseEnter() {
    if (fadeOutTimer) clearTimeout(fadeOutTimer);
}

// Anti Spam for WHOIS server requests
// Rate Limiting 3 minutes per nick
const whoisTimestamps = new Map<string, number>(); // Track WHOIS timestamps per nick

function handleMouseEnter() {
    const now = Date.now();
    const lastRequest = whoisTimestamps.get(ircUser.value.nick) || 0;

    if (now - lastRequest > 180000) { // 3 minutes in ms
        client?.value?.whois(ircUser.value.nick);
        whoisTimestamps.set(ircUser.value.nick, now);
    }
}

function normalizeAwayMessage(message: string | null | undefined): string {
    if (!message) {
        return '...';
    }

    const trimmed = message.trim();

    // Keep only alphanumeric characters plus . _ - and space
    const cleaned = trimmed.replace(/[^\w.\-\s]/g, '');

    // Truncate if necessary
    if (cleaned.length > 17) {
        return cleaned.slice(0, 17) + '...';
    }

    return cleaned;
}
</script>

<template>
    <div class="flex items-center py-2 px-2 rounded-md transition duration-150 ease-out transform hover:shadow-sm hover:-translate-y-0.5 hover:border hover:border-gray-300 dark:hover:border-gray-600 cursor-pointer relative"
        @click="handleLeftClick" @contextmenu="handleRightClick" @mouseenter="handleMouseEnter">
        <div class="shrink-0 relative">
            <img class="w-12 h-12 rounded-full" :src="avatarUrl" alt="User avatar" />

            <!-- Operator Icon -->
            <svg v-if="isOp" class="absolute top-1/2 -left-4 w-[30px] h-[30px] transform -translate-y-1/2 z-10"
                viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <linearGradient id="goldGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stop-color="#FFD700" />
                        <stop offset="100%" stop-color="#FFA500" />
                    </linearGradient>
                    <filter id="dropShadow" x="-20%" y="-20%" width="140%" height="140%">
                        <feDropShadow dx="0" dy="2" stdDeviation="2" flood-color="black" flood-opacity="0.3" />
                    </filter>
                </defs>
                <circle cx="50" cy="50" r="45" fill="url(#goldGradient)" stroke="#d4af37" stroke-width="4"
                    filter="url(#dropShadow)" />
                <text x="49%" y="51%" text-anchor="middle" fill="white" font-size="60" font-weight="bold"
                    dy=".25em">@</text>
            </svg>

            <!-- Voice Icon -->
            <svg v-else-if="isVoice" class="absolute top-1/2 -left-4 w-[30px] h-[30px] transform -translate-y-1/2 z-10"
                viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <linearGradient id="violetGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stop-color="#c084fc" /> <!-- lighter violet -->
                        <stop offset="100%" stop-color="#a855f7" />
                    </linearGradient>
                </defs>
                <circle cx="50" cy="50" r="45" fill="url(#violetGradient)" stroke="#9333ea" stroke-width="4"
                    filter="url(#dropShadow)" />
                <text x="50%" y="53%" text-anchor="middle" fill="white" font-size="60" font-weight="bold"
                    dy=".3em">+</text>
            </svg>

            <!-- Away/Online Dot -->
            <span
                class="absolute bottom-0 left-8 transform translate-y-1/4 w-3.5 h-3.5 border-2 border-white dark:border-gray-800 rounded-full"
                :class="{
                    'bg-gray-300': isAway,
                    'bg-green-400': !isAway
                }">
            </span>

            <!-- Away Message Badge -->
            <span v-if="isAway"
                class="absolute bottom-0 left-12 transform translate-y-1/4 bg-gray-100 text-gray-800 text-xs font-medium px-2.5 py-0.5 rounded-sm dark:bg-gray-700 dark:text-gray-400 border border-gray-500 whitespace-nowrap">
                {{ awayMessage }}
            </span>
        </div>
        <div class="flex-1 min-w-0 ms-3">
            <p class="text-base font-semibold text-gray-900 truncate dark:text-white">{{ nick }}</p>
        </div>

        <!-- Popover rendered in body via teleport -->
        <Teleport to="body">
            <transition name="fade">
                <div v-if="popoverVisible" class="popover-wrapper">
                    <div :id="popoverId" ref="popoverRef"
                        class="fixed z-50 inline-block text-sm text-gray-500 bg-white border border-gray-200 rounded-lg shadow-md p-3 dark:text-gray-400 dark:border-gray-600 dark:bg-gray-800"
                        :style="{ top: popoverPosition.top + 'px', left: popoverPosition.left + 'px' }"
                        @mouseenter="onPopoverMouseEnter" @mouseleave="onPopoverMouseLeave">
                        <UserPopoverContent :channel="channel" :client="client" :whois="whois as Whois"
                            :profile="profile" @switch-tab="emit('switch-tab', $event)" />
                    </div>
                </div>
            </transition>
        </Teleport>
    </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
