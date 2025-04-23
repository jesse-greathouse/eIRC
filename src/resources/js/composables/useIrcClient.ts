import { ref } from 'vue';
import { IrcClient } from '@/irc/IrcClient';
import { buildHandlers } from '@/irc/buildHandlers';
import emitter from '@/lib/emitter';
import { getTabKey } from '@/lib/getTabKey';
import { useIrcLines } from '@/composables/useIrcLines';

/**
 * IrcClient is being instantiated as a singleton.
 * There can only be one instance of IrcClient per user.
 */
const ircClientRef = ref<IrcClient | null>(null);

export function useIrcClient(chat_token: string) {
    if (ircClientRef.value) return ircClientRef.value;

    if (!chat_token) {
        throw new Error('chat_token is required to initialize the IRC client');
    }

    const { addLinesTo, addUserLineTo } = useIrcLines();

    const client = new IrcClient(
        chat_token,
        location.hostname,
        9667,
        (msg) => console.log(`[IRC] ${msg}`),
        (line) => {
            const target = getTabKey(line);
            addLinesTo(target, [line]);
        },
        {
            onJoinChannel: (channel) => {
                const tabId = `channel-${channel}`;
                emitter.emit('joined-channel', channel);
                emitter.emit('switch-tab', tabId);
            },
            onPrivmsg: (nick) => {
                emitter.emit('new-privmsg', nick);
            },
            addUserLineTo,
        }
    );

    Object.entries(buildHandlers()).forEach(([event, handlers]) => {
        handlers.forEach(h => client.addEventHandler(event, h));
    });

    client.connect();

    ircClientRef.value = client;

    // Clean up when user leaves the site
    if (typeof window !== 'undefined') {
        window.addEventListener('beforeunload', () => {
        ircClientRef.value?.disconnect();
        ircClientRef.value = null;
        });
    }

    return client;
}

export function getIrcClient(): IrcClient | null {
  return ircClientRef.value as IrcClient | null;
}
