import type { ChatCommandHandler } from './types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const meCommand: ChatCommandHandler = async ({ client, target, args, tabId, nick, inject }) => {
    const message = args.join(' ').trim();
    if (!message) return;

    await client.action(target, message);

    inject(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: `* ${nick} ${message}`,
        command: 'ACTION',
        params: [target, message],
        prefix: `${nick}!local@client`,
    }));
};
