import type { ChatCommandHandler } from './types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const joinCommand: ChatCommandHandler = async ({ client, args, nick, inject, switchTab }) => {
    const channel = args[0];
    if (!channel || !channel.startsWith('#')) return;

    await client.join(channel);

    // Inject the echo message into the current tab (where user typed the command)
    const message = `→ JOIN ${channel}`;
    const ircLine = new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'JOIN',
        params: [channel],
        prefix: `${nick}!local@client`,
    });

    inject('console', ircLine);

    const newTabId = `channel-${channel}`;
    switchTab?.(newTabId);
};
