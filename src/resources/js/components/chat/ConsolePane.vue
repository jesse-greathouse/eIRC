<script setup lang="ts">
import BaseChatPane from './BaseChatPane.vue';
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
            <ul class="text-[14px] font-mono text-gray-600 space-y-1">
                <li v-for="(line, index) in tabLines" :key="line.id ?? index">
                    <span v-if="line.command === 'NOTICE'" class="font-semibold text-green-600">
                        {{ line.params[1] ?? line.raw }}
                    </span>
                    <span v-else-if="line.command === 'PING'" class="font-semibold text-pink-500">
                        {{ line.raw }}
                    </span>
                    <span v-else>
                        {{ line.raw }}
                    </span>
                </li>
            </ul>
        </template>

        <template #input>
            <ChatInput :tabId="props.tabId" :client="props.client" />
        </template>
    </BaseChatPane>
</template>
