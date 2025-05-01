import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const joinHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const userNick = line.prefix?.split('!')[0];
    const channelName = line.params[0];
    if (!channelName || !userNick) return;

    // Refresh WHOIS for userNick.
    await client.whois(userNick);

    client.addUserToChannel(userNick, channelName);

    const isSelf = userNick === client.nick;

    if (isSelf) {
        client.opts.onJoinChannel?.(channelName);
    }

    const tabId = `channel-${channelName}`;

    // Compose a new IrcLine for buffer rendering
    const bufferLine = cloneLine(line);
    bufferLine.command = line.command;
    bufferLine.raw = `${userNick} has joined ${channelName}`;

    client.opts.addUserLineTo?.(tabId, bufferLine);
};
