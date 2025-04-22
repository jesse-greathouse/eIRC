import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const partHandler: IrcEventHandler = (client, line) => {
    const userNick = line.prefix?.split('!')[0];
    const channelName = line.params[0];
    if (!userNick || !channelName) return;

    const user = client.getOrCreateUser(userNick);
    const channel = client.getOrCreateChannel(channelName);

    user.removeChannel(channel);
    channel.removeUser(user);

    // Optionally: clean up empty channels or users
    // if (channel.users.size === 0) client.channels.delete(channelName);

    const tabId = `channel-${channelName}`;
    const message = `${userNick} has left ${channelName}`;
    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'PART',
        params: [channelName, message],
        prefix: `${userNick}!left@server`,
    }));
};
