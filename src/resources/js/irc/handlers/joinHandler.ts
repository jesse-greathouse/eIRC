import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const joinHandler: IrcEventHandler = (client, line) => {
    const user = line.prefix?.split('!')[0];
    const channel = line.params[0];
    if (!channel || !user) return;

    const isSelf = user === client.nick;

    if (isSelf) {
        client.joinChannel(channel);
        client.opts.onJoinChannel?.(channel);
    }

    // The original message gets send to the console.
    // Dupe the IrcLine and send it to the channel tab.
    const message = `${user} has joined ${channel}`;
    const timestamp = Date.now();
    const base = {
        id: nanoid(),
        timestamp,
        raw: message,
        command: 'JOIN',
        params: [channel, message],
        prefix: `${user}!joined@server`,
    };

    // Also send to the new channel tab
    const tabId = `channel-${channel}`;
    client.opts.addUserLineTo?.(tabId, new IrcLine({ ...base }));
};
