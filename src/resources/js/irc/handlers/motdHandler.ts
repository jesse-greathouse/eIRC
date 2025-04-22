import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const motdHandler: IrcEventHandler = (client, line) => {
    const motdLine = line.params[1] ?? '';
    const command = line.command;

    const message = `[MOTD] ${motdLine}`;
    const tabId = 'console';

    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command,
        params: [motdLine],
        prefix: 'server',
    }));
};
