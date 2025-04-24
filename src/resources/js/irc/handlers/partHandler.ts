import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const partHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const userNick = line.prefix?.split('!')[0];
    const channelName = line.params.shift();

    if (!userNick || !channelName) return;

    const user = client.getOrCreateUser(userNick);
    const channel = client.getOrCreateChannel(channelName);
    const partMsg = line.params.filter(str => typeof str === 'string') // Ensure it's a string
            .map(str => str.replace(/^"|"$/g, '')) // Remove leading/trailing quotes
            .join(' ');

    channel.removeUser(user);
    user.removeChannel(channel);

    // clean up empty channels or users
    if (channel.users.size === 0) client.channels.delete(channelName);

    const tabId = `channel-${channelName}`;
    const message = `${userNick} has left ${channelName} ${partMsg}`;
    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'PART',
        params: [channelName, message],
        prefix: `${userNick}!left@server`,
    }));
};
