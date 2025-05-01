<script setup lang="ts">
import { computed, ref, onMounted } from 'vue';
import { IRC_EVENT_KEYS } from '@/irc/constants';
import { classifyLine } from '@/irc/utils/classifyLine';
import type { IrcLine } from '@/types/IrcLine';
import type { IrcClient } from '@/irc/IrcClient';
import { getUser, renderEventText } from './helpers';
import { linkifyHtml } from '@/composables/useLinkify';
import { getIrcClient } from '@/composables/useIrcClient';
import ChannelPaneHeader from './ChannelPaneHeader.vue';
import ChannelUserListCard from './ChannelUserListCard.vue';
import BaseChatPane from './BaseChatPane.vue';
import ChatInput from './ChatInput.vue';

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
}>();

// IRC Client must be ref + awaited
const client = ref<IrcClient | null>(null);

onMounted(async () => {
    client.value = await getIrcClient();
});

const channel = computed(() => {
    if (!client.value) return null;
    const channelName = props.tabId.replace(/^channel-/, '');
    return client.value.channels.get(channelName) ?? null;
});

const classifiedTabLines = computed(() => {
    const lines = props.lines.get(props.tabId)?.map(line => ({
        line,
        type: classifyLine(line, 'channel'),
    })) ?? [];

    return lines;
});

const userVersion = ref('');

const channelUsers = computed(() => {
    void userVersion.value; // Dependency for reactivity
    return channel.value?.users ?? [];
});

function formatNoticeLine(line: IrcLine): string {
    if (line.command === IRC_EVENT_KEYS.RPL_TOPICWHOTIME && line.params.length >= 3) {
        const setter = line.params[2]?.split('!')[0] ?? 'unknown';
        return `-- ${setter}`;
    }

    if (line.command === IRC_EVENT_KEYS.TOPIC) {
        const topic = line.params[1] ?? '';
        const setter = line.prefix?.split('!')[0] ?? 'unknown';
        return `${linkifyHtml(topic)}<br><span>-- ${setter}</span>`;
    }

    return linkifyHtml(line.params[2] ?? line.raw ?? '');
}
</script>

<template>
    <BaseChatPane v-bind="props">
        <!-- Header for Channel -->
        <template #header>
            <ChannelPaneHeader :channel="channel?.name" :topic="channel?.topic" />
        </template>

        <template #default>
            <div class="flex w-full h-full gap-4">
                <!-- Chat Buffer -->
                <ul class="flex-1 text-gray-700 dark:text-gray-300 space-y-1 pt-4">
                    <li v-for="(entry, index) in classifiedTabLines" :key="entry.line.id ?? index">
                        <template v-if="entry.type === 'action'">
                            <span class="text-gray-400 italic font-semibold">
                                * {{ getUser(entry.line) }} {{ entry.line.params[1] }}
                            </span>
                        </template>

                        <template v-else-if="entry.type === 'message'">
                            <span class="font-medium text-indigo-500">{{ getUser(entry.line) }}</span>:
                            {{ entry.line.params[1] }}
                        </template>

                        <template v-else-if="entry.type === 'notice'">
                            <span class="font-semibold text-green-600" v-html="formatNoticeLine(entry.line)"></span>
                        </template>

                        <template v-else-if="entry.type === 'server'">
                            <span class="font-semibold text-blue-400 italic"
                                v-html="formatNoticeLine(entry.line)"></span>
                        </template>

                        <template v-else-if="entry.type === 'event'">
                            <span class="font-semibold text-cyan-500"
                                v-html="`• ${renderEventText(entry.line)}`"></span>
                        </template>
                    </li>
                </ul>

                <!-- User List -->
                <div class="w-sm border-l border-gray-300 dark:border-gray-700 pl-4 py-4">
                    <div
                        class="w-full p-4 bg-white border border-gray-200 rounded-lg shadow-sm dark:bg-gray-800 dark:border-gray-700">
                        <div class="flow-root">
                            <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
                                <li v-for="user in channelUsers" :key="user.nick">
                                    <ChannelUserListCard :channel="channel" :user="client?.users.get(user.nick) ?? user"
                                        :tab-id="props.tabId" @switch-tab="emit('switch-tab', $event)" />
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <template #input>
            <ChatInput :tab-id="props.tabId" @switch-tab="emit('switch-tab', $event)" />
        </template>
    </BaseChatPane>
</template>
