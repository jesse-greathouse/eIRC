<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount, computed, nextTick } from 'vue';
import type { User as IrcUser } from '@/irc/models/User';
import type { Whois } from '@/irc/models/Whois'
import type { IrcClient } from '@/irc/IrcClient';
import type { Profile } from '@/types';
import emitter from '@/lib/emitter'; // Same event bus as elsewhere
import { useProfiles } from '@/composables/useProfiles';
import { getIrcClient } from '@/composables/useIrcClient';
import UserPopoverContent from '@/components/chat/UserPopoverContent.vue';

interface Props {
    user: IrcUser;
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

// User Context Popover
const popoverVisible = ref(false);
const popoverId = `popover-${props.user.nick}`;
const popoverPosition = ref({ top: 0, left: 0 });

// Avatar URL directly from profile
const avatarUrl = computed(() => {
    return profile.value?.selected_avatar?.base64_data || '/avatar-placeholder.png';
});

// Nick straight from ircUser
const nick = computed(() => ircUser.value.nick);

// Away handling.
const isAway = ref(false);
const awayMessage = ref('...');

onMounted(async () => {
    client.value = await getIrcClient();
    initialize();

    // close all popovers event handler.
    emitter.on('close-all-popovers', () => {
        popoverVisible.value = false;
    });
});

onBeforeUnmount(() => {
    emitter.off('close-all-popovers');
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
function handleRightClick(event: MouseEvent) {
    event.preventDefault();

    emitter.emit('close-all-popovers'); // Close any other open popovers

    const popoverWidth = 288; // Approx. width of w-72 (72 * 4 = 288px)
    popoverPosition.value = {
        top: event.clientY,
        left: event.clientX - popoverWidth,
    };
    popoverVisible.value = true;
    if (fadeOutTimer) clearTimeout(fadeOutTimer);
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
    <div
        class="flex items-center py-2 px-2 rounded-md transition duration-150 ease-out transform hover:shadow-sm hover:-translate-y-0.5 hover:border hover:border-gray-300 dark:hover:border-gray-600 cursor-pointer relative"
        @click="handleLeftClick" @contextmenu="handleRightClick" @mouseenter="handleMouseEnter">
        <div class="shrink-0 relative">
            <img class="w-12 h-12 rounded-full" :src="avatarUrl" alt="User avatar" />

            <!-- Away/Online Dot -->
            <span
                class="absolute bottom-0 left-8 transform translate-y-1/4 w-3.5 h-3.5 border-2 border-white dark:border-gray-800 rounded-full"
                :class="{
                    'bg-gray-300': isAway,
                    'bg-green-400': !isAway
                }">
            </span>

            <!-- Away Message Badge -->
            <span
                v-if="isAway"
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
                <div
                    v-if="popoverVisible" :id="popoverId"
                    class="fixed z-50 inline-block text-sm text-gray-500 bg-white border border-gray-200 rounded-lg shadow-md p-3 dark:text-gray-400 dark:border-gray-600 dark:bg-gray-800"
                    :style="{ top: popoverPosition.top + 'px', left: popoverPosition.left + 'px' }"
                    @mouseenter="onPopoverMouseEnter" @mouseleave="onPopoverMouseLeave">
                    <!-- Force UserPopoverContent to fill the popover width -->
                    <div class="w-full">
                        <UserPopoverContent :whois="whois as Whois" :profile="profile" />
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
