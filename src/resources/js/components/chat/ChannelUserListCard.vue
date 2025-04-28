<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount, computed } from 'vue';
import type { User as IrcUser } from '@/irc/models/User';
import type { IrcClient } from '@/irc/IrcClient';
import type { Profile } from '@/types';
import emitter from '@/lib/emitter'; // Same event bus as elsewhere
import { useProfiles } from '@/composables/useProfiles';
import { getIrcClient } from '@/composables/useIrcClient';
import UserPopoverContent from '@/components/chat/UserPopoverContent.vue';

const props = defineProps<{
    user: IrcUser;
}>();

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const client = ref<IrcClient | null>(null);
const { getProfile } = useProfiles();

const ircUser = ref<IrcUser>(props.user);
const profile = ref<Profile | null>(null);
const popoverVisible = ref(false);
const popoverId = `popover-${props.user.nick}`;
const popoverPosition = ref({ top: 0, left: 0 });
const whoisTimestamps = new Map<string, number>(); // Track WHOIS timestamps per nick
let fadeOutTimer: ReturnType<typeof setTimeout> | null = null;

// Avatar URL directly from profile
const avatarUrl = computed(() => {
    return profile.value?.selected_avatar?.base64_data || '/avatar-placeholder.png';
});

// Nick straight from ircUser
const username = computed(() => ircUser.value.nick);

// Direct reference to Whois for template use
const whois = computed(() => ircUser.value.whois);

// Load profile based on whois.realName
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
}

onMounted(async () => {
    client.value = await getIrcClient();
    initialize();
    emitter.on('close-all-popovers', () => {
        popoverVisible.value = false;
    });
});

onBeforeUnmount(() => {
    emitter.off('close-all-popovers');
});

// Watch WHOIS realName changes for dynamic profile updates
watch(() => ircUser.value.whois.realName, async (newRealname) => {
    if (newRealname) {
        await loadProfile(newRealname);
    }
});

// Watch for full user replacement
watch(() => props.user, (newUser) => {
    ircUser.value = newUser;
    initialize();
});

// Left-click to open privmsg tab
function handleLeftClick() {
    emit('switch-tab', `pm-${props.user.nick}`);
}

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
function handleMouseEnter() {
    const now = Date.now();
    const lastRequest = whoisTimestamps.get(ircUser.value.nick) || 0;

    if (now - lastRequest > 180000) { // 3 minutes in ms
        client?.value?.whois(ircUser.value.nick);
        whoisTimestamps.set(ircUser.value.nick, now);
    }
}
</script>

<template>
    <div class="flex items-center py-2 px-2 rounded-md transition duration-150 ease-out transform hover:shadow-sm hover:-translate-y-0.5 hover:border hover:border-gray-300 dark:hover:border-gray-600 cursor-pointer relative"
        @click="handleLeftClick" @contextmenu="handleRightClick" @mouseenter="handleMouseEnter">
        <div class="shrink-0">
            <img class="w-12 h-12 rounded-full" :src="avatarUrl" alt="User avatar" />
        </div>
        <div class="flex-1 min-w-0 ms-3">
            <p class="text-base font-semibold text-gray-900 truncate dark:text-white">{{ username }}</p>
        </div>

        <!-- Popover rendered in body via teleport -->
        <Teleport to="body">
            <transition name="fade">
                <div v-if="popoverVisible" :id="popoverId"
                    class="fixed z-50 inline-block text-sm text-gray-500 bg-white border border-gray-200 rounded-lg shadow-md p-3 dark:text-gray-400 dark:border-gray-600 dark:bg-gray-800"
                    :style="{ top: popoverPosition.top + 'px', left: popoverPosition.left + 'px' }"
                    @mouseenter="onPopoverMouseEnter" @mouseleave="onPopoverMouseLeave">
                    <!-- Force UserPopoverContent to fill the popover width -->
                    <div class="w-full">
                        <UserPopoverContent :whois="whois" :profile="profile" />
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
