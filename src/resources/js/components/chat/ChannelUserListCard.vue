<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import type { User } from '@/irc/models/User';
import { useProfiles } from '@/composables/useProfiles';

const props = defineProps<{
    user: User;
}>();

const { getProfile } = useProfiles();

const avatarUrl = ref('/avatar-placeholder.png');
const username = computed(() => props.user.nick);
const realname = computed(() => props.user.realName || props.user.nick); // fallback if realName is null

onMounted(async () => {
    const profile = await getProfile(realname.value);

    if (profile && profile.selected_avatar?.base64_data) {
        avatarUrl.value = profile.selected_avatar?.base64_data;
    }
});

watch(realname, async (newRealname) => {
    const profile = await getProfile(newRealname);

    if (profile && profile.selected_avatar?.base64_data) {
        avatarUrl.value = profile.selected_avatar.base64_data;
    } else {
        avatarUrl.value = '/avatar-placeholder.png'; // fallback if profile disappears
    }
}, { immediate: true });
</script>

<template>
    <div
        class="flex items-center py-3 sm:py-4 px-2 rounded-lg transition-transform duration-200 ease-in-out hover:shadow-lg hover:-translate-y-1 hover:border hover:border-gray-300 dark:hover:border-gray-600 cursor-pointer">
        <div class="shrink-0">
            <img class="w-8 h-8 rounded-full" :src="avatarUrl" alt="User avatar" />
        </div>
        <div class="flex-1 min-w-0 ms-4">
            <p class="text-sm font-medium text-gray-900 truncate dark:text-white">{{ username }}</p>
        </div>
    </div>
</template>
