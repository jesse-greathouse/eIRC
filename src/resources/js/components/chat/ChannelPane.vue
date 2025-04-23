<script setup lang="ts">
import { computed } from 'vue';
import type { IrcLine } from '@/types/IrcLine';
import { classifyLine, getUser, renderEventText } from './helpers';
import { getIrcClient } from '@/composables/useIrcClient';
import ChannelPaneHeader from './ChannelPaneHeader.vue';
import BaseChatPane from './BaseChatPane.vue';
import ChatInput from './ChatInput.vue';

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
</script>

<template>
    <BaseChatPane v-bind="props">
        <!-- Header for Channel -->
        <template #header>
            <ChannelPaneHeader :channel="channel?.name" :topic="channel?.topic" />
        </template>

        <template #default="{ tabLines }">
            <ul class="text-sm text-gray-700 dark:text-gray-300 space-y-1">
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
        </template>

        <template #input>
            <ChatInput :tabId="props.tabId" @switch-tab="emit('switch-tab', $event)" />
        </template>
    </BaseChatPane>
</template>
