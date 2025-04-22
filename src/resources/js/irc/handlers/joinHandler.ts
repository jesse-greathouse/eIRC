import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const joinHandler: IrcEventHandler = (client, line) => {
    const userNick = line.prefix?.split('!')[0];
    const channelName = line.params[0];
    if (!channelName || !userNick) return;

    client.addUserToChannel(userNick, channelName);

    const isSelf = userNick === client.nick;

    if (isSelf) {
        client.opts.onJoinChannel?.(channelName);
    }

    // Compose a new IrcLine for buffer rendering
   const message = `${userNick} has joined ${channelName}`;
    const bufferLine = new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'JOIN',
        params: [channelName, message],
        prefix: `${userNick}!joined@server`,
    });

    const tabId = `channel-${channelName}`;
    client.opts.addUserLineTo?.(tabId, bufferLine);
};
