import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const quitHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const userNick = line.prefix?.split('!')[0];
    if (!userNick) return;

    let quitMsg = '';

    if (line.params?.length) {
        quitMsg += ': ';
        quitMsg += line.params.filter(str => typeof str === 'string') // Ensure it's a string
            .map(str => str.replace(/^"|"$/g, '')) // Remove leading/trailing quotes
            .join(' ');
    }

    const user = client.getOrCreateUser(userNick);

    for (const channel of user.channels) {
        channel.removeUser(user);

        const tabId = `channel-${channel.name}`;
        const message = `${userNick} has quit ${quitMsg}`;
        client.opts.addUserLineTo?.(tabId, new IrcLine({
            id: nanoid(),
            timestamp: Date.now(),
            raw: message,
            command: 'QUIT',
            params: [channel.name, message],
            prefix: `${userNick}!quit@server`,
        }));
    }

    client.users.delete(userNick);
};
