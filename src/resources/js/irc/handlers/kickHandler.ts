import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const kickHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[0];
    const kickedNick = line.params[1];
    const reason = line.params[2] ?? '';

    if (!channelName || !kickedNick) return;

    const channel = client.getOrCreateChannel(channelName);
    const kickedUser = client.getOrCreateUser(kickedNick);

    channel.removeUser(kickedUser);
    kickedUser.removeChannel(channel);

    const tabId = `channel-${channelName}`;

    // Compose a new IrcLine for buffer rendering
    const bufferLine = cloneLine(line);
    bufferLine.command = line.command;
    bufferLine.raw = `${kickedNick} was kicked from ${channelName} (${reason})`;

    client.opts.addUserLineTo?.(tabId, bufferLine);

    client.opts.onKick?.(kickedNick, channelName, reason);
};
