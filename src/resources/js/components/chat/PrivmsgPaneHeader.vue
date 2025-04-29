<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import BasePaneHeader from './BasePaneHeader.vue';
import ChannelUserListCard from './ChannelUserListCard.vue';
import { getIrcClient } from '@/composables/useIrcClient';
import type { IrcClient } from '@/irc/IrcClient';

const props = defineProps<{
    nick: string;
}>();

const client = ref<IrcClient | null>(null);

onMounted(async () => {
    client.value = await getIrcClient();
});

const user = computed(() => {
    if (!client.value) return null;
    return client.value.users.get(props.nick) ?? null;
});
</script>

<template>
    <BasePaneHeader>
        <div class="flex items-center gap-2">
            <ChannelUserListCard v-if="user" :user="user" :tab-id="`pm-${props.nick}`" />
            <span v-else class="text-gray-500 text-sm">Loading...</span>
        </div>
    </BasePaneHeader>
</template>
