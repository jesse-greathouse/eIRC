import type { IrcEventHandler } from '../types';

export const joinHandler: IrcEventHandler = (client, line) => {
    const user = line.prefix?.split('!')[0];
    const channel = line.params[0];

    if (!channel || !user) return;

    // Only trigger tab creation if it's this client joining
    const isSelf = user === client.nick; // client.nick must be set during connection/login
    if (isSelf) {
        client.joinChannel(channel);
        client.opts.onJoinChannel?.(channel);
    }
};
