import { ref } from 'vue';
import emitter from '@/lib/emitter';
import { IrcClient } from '@/irc/IrcClient';
import { buildHandlers } from '@/irc/buildHandlers';
import { getTabKey } from '@/lib/getTabKey';
import { useClient } from '@/composables/useClient';
import { useIrcLines } from '@/composables/useIrcLines';

const ircClientRef = ref<IrcClient | null>(null);

// Promise to resolve once the IRC client is ready
let clientReadyPromise: Promise<IrcClient> | null = null;
let resolveClientReady: ((client: IrcClient) => void) | null = null;

/**
 * Instantiates the singleton IrcClient.
 */
export function useIrcClient(chat_token: string) {
    if (ircClientRef.value) return ircClientRef.value;

    if (!chat_token) {
        throw new Error('chat_token is required to initialize the IRC client');
    }

    const { coreApi } = useClient('core');
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
            onMode: (nick, channel, mode) => {
                emitter.emit('mode-change', { nick, channel, mode });
            },
            onPrivmsg: (nick) => {
                emitter.emit('new-privmsg', nick);
            },
            addUserLineTo,
            onWelcome: async (nick) => {
                // WHOIS for accurate realname update
                await client?.whois(nick);
            },
            onNick: async (oldNick, newNick) => {
                // WHOIS to sync client data
                await client?.whois(newNick);
            },
            onWhois: async (nick, realname) => {
                try {
                    await coreApi.updateUser(realname, { nick, realname });
                } catch (err) {
                    console.error(`[API Sync] Failed to sync onWhois:`, err);
                }
            },
        }
    );

    Object.entries(buildHandlers()).forEach(([event, handlers]) => {
        handlers.forEach(h => client.addEventHandler(event, h));
    });

    client.connect();

    ircClientRef.value = client;

    // Resolve the promise now that it's available
    if (resolveClientReady) {
        resolveClientReady(client);
    }

    // Clean up when user leaves the site
    if (typeof window !== 'undefined') {
        window.addEventListener('beforeunload', () => {
            ircClientRef.value?.disconnect();
            ircClientRef.value = null;
            clientReadyPromise = null;
            resolveClientReady = null;
        });
    }

    return client;
}

/**
 * Returns a promise that resolves to the IrcClient once it's available.
 */
export async function getIrcClient(): Promise<IrcClient> {
    if (ircClientRef.value) {
        return ircClientRef.value as IrcClient;
    }

    if (!clientReadyPromise) {
        clientReadyPromise = new Promise<IrcClient>((resolve) => {
            resolveClientReady = resolve;
        });
    }

    return clientReadyPromise;
}
