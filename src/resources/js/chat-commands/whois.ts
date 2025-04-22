import type { ChatCommandHandler } from './types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const whoisCommand: ChatCommandHandler = async ({ client, args, nick, inject }) => {
    const target = args[0]?.trim();
    if (!target) return;

    await client.whois(target);

    inject('console', new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: `Whois ${target}...`,
        command: 'WHOIS',
        params: [target],
        prefix: `${nick}!local@client`,
    }));
};
