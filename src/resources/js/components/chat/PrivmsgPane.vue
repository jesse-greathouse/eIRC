<script setup lang="ts">
import BaseChatPane from './BaseChatPane.vue';
import PrivmsgPaneHeader from './PrivmsgPaneHeader.vue'
import ChatInput from './ChatInput.vue';
import { classifyLine } from '@/irc/utils/classifyLine';
import { getUser } from './helpers';
import type { IrcLine } from '@/types/IrcLine';

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const props = defineProps<{
    lines: Map<string, IrcLine[]>;
    tabId: string;
}>();

</script>

<template>
    <BaseChatPane v-bind="props">
        <!-- Header for Privmsg -->
        <template #header>
            <PrivmsgPaneHeader :nick="props.tabId.replace(/^pm-/, '')" status="Online" />
        </template>

        <template #default="{ tabLines }">
            <ul class="text-gray-700 dark:text-gray-300 space-y-1">
                <li v-for="(line, index) in tabLines" :key="line.id ?? index">
                    <template v-if="classifyLine(line, 'privmsg') === 'message'">
                        <span class="font-medium text-gray-400">{{ getUser(line) }}</span>:
                        {{ line.params[1] }}
                    </template>
                    <template v-else-if="classifyLine(line, 'privmsg') === 'notice'">
                        <span class="font-semibold text-green-600">{{ line.params[1] }}</span>
                    </template>
                    <template v-else-if="entry.type === 'action'">
                        <span class="text-indigo-500 italic">
                            * {{ getUser(entry.line) }} {{ entry.line.params[1] }}
                        </span>
                    </template>
                    <template v-else>
                        {{ line.raw }}
                    </template>
                </li>
            </ul>
        </template>

        <template #input>
            <ChatInput :tabId="props.tabId" @switch-tab="emit('switch-tab', $event)" />
        </template>
    </BaseChatPane>
</template>
