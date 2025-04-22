import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const kickHandler: IrcEventHandler = (client, line) => {
    const channelName = line.params[0];
    const kickedNick = line.params[1];
    const reason = line.params[2] ?? '';

    if (!channelName || !kickedNick) return;

    const channel = client.getOrCreateChannel(channelName);
    const kickedUser = client.getOrCreateUser(kickedNick);

    channel.removeUser(kickedUser);
    kickedUser.removeChannel(channel);

    const tabId = `channel-${channelName}`;
    const message = `${kickedNick} was kicked from ${channelName} (${reason})`;
    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'KICK',
        params: [channelName, kickedNick, reason],
        prefix: `${kickedNick}!kicked@server`,
    }));
};
