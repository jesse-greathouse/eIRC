<script setup lang="ts">
import { computed, ref, watchEffect, watch } from 'vue';
import type { IrcLine } from '@/types/IrcLine';
import { classifyLine, getUser, renderEventText } from './helpers';
import { getIrcClient } from '@/composables/useIrcClient';
import ChannelPaneHeader from './ChannelPaneHeader.vue';
import ChannelUserListCard from './ChannelUserListCard.vue';
import BaseChatPane from './BaseChatPane.vue';
import ChatInput from './ChatInput.vue';
import { User } from '@/irc/models/User';

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
}>();

const client = getIrcClient();

const channel = computed(() => {
    const channelName = props.tabId.replace(/^channel-/, '');
    return client?.channels.get(channelName);
});

const userVersion = ref('');

const channelUsers = computed(() => {
    userVersion.value; // Dependency for reactivity
    return channel.value?.users ?? [];
});

// watch(channelUsers, (oldUsers, newUsers) => {
//     console.log('Channel users updated:');
//     if (oldUsers instanceof Set) {
//         console.log("oldUsers Set size");
//         console.log(oldUsers.size); // TypeScript now knows it's a Set
//     }

//     if (newUsers instanceof Set) {
//         console.log("newUsers Set size");
//         console.log(newUsers.size); // TypeScript now knows it's a Set
//     }
// });
</script>

<template>
    <BaseChatPane v-bind="props">
        <!-- Header for Channel -->
        <template #header>
            <ChannelPaneHeader :channel="channel?.name" :topic="channel?.topic" />
        </template>

        <template #default="{ tabLines }">
            <div class="flex w-full h-full gap-4">
                <!-- Chat Buffer -->
                <ul class="flex-1 text-sm text-gray-700 dark:text-gray-300 space-y-1">
                    <li v-for="(line, index) in tabLines" :key="line.id ?? index">
                        <template v-if="classifyLine(line, 'channel') === 'message'">
                            <span class="font-medium text-indigo-500">{{ getUser(line) }}</span>:
                            {{ line.params[1] }}
                        </template>
                        <template v-else-if="classifyLine(line, 'channel') === 'notice'">
                            <span class="font-semibold text-green-600">{{ line.params[1] }}</span>
                        </template>
                        <template v-else-if="classifyLine(line, 'channel') === 'event'">
                            <span class="font-semibold text-cyan-500">• {{ renderEventText(line) }}</span>
                        </template>
                    </li>
                </ul>

                <!-- User List -->
                <div class="w-[250px] border-l border-gray-300 dark:border-gray-700 pl-4">
                    <div
                        class="w-full p-4 bg-white border border-gray-200 rounded-lg shadow-sm dark:bg-gray-800 dark:border-gray-700">
                        <div class="flow-root">
                            <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
                                <li v-for="user in channelUsers" :key="user.nick">
                                    <ChannelUserListCard :user="user" />
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <template #input>
            <ChatInput :tabId="props.tabId" @switch-tab="emit('switch-tab', $event)" />
        </template>
    </BaseChatPane>
</template>
