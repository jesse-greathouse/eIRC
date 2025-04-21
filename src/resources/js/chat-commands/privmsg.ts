import type { ChatCommandHandler } from './types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const privmsgCommand: ChatCommandHandler = async ({ client, args, nick, inject }) => {
    const [target, message] = [args.shift(), args.join(' ').trim()];
    if (!target || !message) return;

    const tabId = target.startsWith('#') ? `channel-${target}` : `pm-${target}`;

    await client.msg(target, message);

    inject(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: `<${nick}> ${message}`,
        command: 'PRIVMSG',
        params: [target, message],
        prefix: `${nick}!local@client`,
    }));
};
