<script setup lang="ts">
import BaseChatPane from './BaseChatPane.vue';
import { classifyLine, getUser, renderEventText } from './helpers';
import ChatInput from './ChatInput.vue';
import type { IrcLine } from '@/types/IrcLine';
import { IrcClient } from '@/irc/IrcClient';

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
    client: IrcClient;
}>();
</script>

<template>
    <BaseChatPane v-bind="props">
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
            <ChatInput :tabId="props.tabId" :client="props.client" />
        </template>
    </BaseChatPane>
</template>
