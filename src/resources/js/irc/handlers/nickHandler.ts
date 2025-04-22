import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const nickHandler: IrcEventHandler = (client, line) => {
    const oldNick = line.prefix?.split('!')[0];
    const newNick = line.params[0];
    if (!oldNick || !newNick) return;

    const user = client.getOrCreateUser(oldNick);
    user.nick = newNick;

    // Update all channels this user is in
    for (const channel of user.channels) {
        channel.removeUser(user); // Remove with oldNick reference
        client.users.delete(oldNick);

        const newUser = client.getOrCreateUser(newNick);
        newUser.channels = user.channels;
        newUser.modes = user.modes;

        channel.addUser(newUser);

        const tabId = `channel-${channel.name}`;
        const message = `${oldNick} is now known as ${newNick}`;
        client.opts.addUserLineTo?.(tabId, new IrcLine({
            id: nanoid(),
            timestamp: Date.now(),
            raw: message,
            command: 'NICK',
            params: [newNick],
            prefix: `${oldNick}!nick@server`,
        }));
    }

    // If it's the client itself
    if (oldNick === client.nick) {
        client.nick = newNick;
    }
};
