<script setup lang="ts">
import { ref, computed } from 'vue';
import { parseIrcLine } from '@/lib/parseIrcLine';
import { useChatTabs } from '@/composables/useChatTabs';
import { commandMap } from '@/chat-commands/commandMap';
import { nanoid } from 'nanoid';
import type { IrcClient } from '@/irc/IrcClient';
import { IrcLine } from '@/types/IrcLine';

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const props = defineProps<{
    tabId: string;
    client: IrcClient;
}>();

const input = ref('');
const { getNameByTabId } = useChatTabs();

const target = computed(() => getNameByTabId(props.tabId));

async function handleSubmit() {
    const rawInput = input.value.trim();
    if (!rawInput) return;

    const nick = props.client.nick || '...';

    try {
        if (rawInput.startsWith('/')) {
            const commandText = rawInput.slice(1);
            const parsed = parseIrcLine(commandText);

            if (!parsed.command) throw new Error('Invalid IRC command');

            const command = parsed.command.toUpperCase();
            const args = parsed.params ?? [];

            const handler = commandMap[command];

            if (handler) {
                await handler({
                    commandText,
                    args,
                    rawInput,
                    tabId: props.tabId,
                    nick,
                    target: target.value,
                    client: props.client,
                    inject: (tabId, line) => {
                        props.client.opts.addUserLineTo?.(tabId, line);
                    },
                    switchTab: (tabId) => emit('switch-tab', tabId),
                });
            } else {
                // Fallback: treat it as a raw /input
                await props.client.input(commandText);

                props.client.opts.addUserLineTo?.('console', new IrcLine({
                    id: nanoid(),
                    timestamp: Date.now(),
                    raw: `→ ${commandText}`,
                    command,
                    params: args,
                    prefix: `${nick}!local@client`,
                }));
            }
        } else {
            // Normal chat message
            await props.client.msg(target.value, rawInput);

            props.client.opts.addUserLineTo?.(props.tabId, new IrcLine({
                id: nanoid(),
                timestamp: Date.now(),
                raw: `<${nick}> ${rawInput}`,
                command: 'PRIVMSG',
                params: [target.value, rawInput],
                prefix: `${nick}!local@client`,
            }));
        }
    } catch (err: unknown) {
        if (err instanceof Error) {
            console.warn('Send failed:', err.message);
        } else {
            console.warn('Send failed:', err);
        }
    }

    input.value = '';
}
</script>

<template>
    <form @submit.prevent="handleSubmit" class="flex w-full h-16">
        <input v-model="input" type="text" placeholder="Message..."
            class="flex-grow w-0 px-4 py-2 rounded-xl bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none" />
        <button type="submit" class="w-32 ml-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-semibold">
            Send
        </button>
    </form>
</template>
