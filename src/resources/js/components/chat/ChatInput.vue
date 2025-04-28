<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { parseIrcLine } from '@/lib/parseIrcLine';
import { IrcClient } from '@/irc/IrcClient';
import { useChatTabs } from '@/composables/useChatTabs';
import { getIrcClient } from '@/composables/useIrcClient';
import { commandMap } from '@/chat-commands/commandMap';
import { nanoid } from 'nanoid';
import { IrcLine } from '@/types/IrcLine';

const emit = defineEmits<{
    (e: 'switch-tab', tabId: string): void;
}>();

const props = defineProps<{
    tabId: string;
}>();

const input = ref('');
const { getNameByTabId } = useChatTabs();
const client = ref<Awaited<ReturnType<typeof getIrcClient>> | null>(null);
const target = computed(() => getNameByTabId(props.tabId));
const nick = computed(() => client.value?.nick || '...');

onMounted(async () => {
    client.value = await getIrcClient();
});

async function handleSubmit() {
    const rawInput = input.value.trim();
    if (!rawInput || !client.value) return;

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
                    nick: nick.value,
                    target: target.value,
                    client: client.value as IrcClient,
                    inject: (tabId, line) => {
                        client.value?.opts.addUserLineTo?.(tabId, line);
                    },
                    switchTab: (tabId) => emit('switch-tab', tabId),
                });
            } else {
                await client.value.input(commandText);
                client.value.opts.addUserLineTo?.('console', new IrcLine({
                    id: nanoid(),
                    timestamp: Date.now(),
                    raw: `→ ${commandText}`,
                    command,
                    params: args,
                    prefix: `${nick.value}!local@client`,
                }));
            }
        } else {
            await client.value.msg(target.value, rawInput);
            client.value.opts.addUserLineTo?.(props.tabId, new IrcLine({
                id: nanoid(),
                timestamp: Date.now(),
                raw: `<${nick.value}> ${rawInput}`,
                command: 'PRIVMSG',
                params: [target.value, rawInput],
                prefix: `${nick.value}!local@client`,
            }));
        }
    } catch (err: unknown) {
        console.warn('Send failed:', err instanceof Error ? err.message : err);
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
