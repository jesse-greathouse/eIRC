import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const rplTopicWhoTimeHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[1];
    const setter = line.params[2];
    const timestamp = new Date(parseInt(line.params[3] ?? '0') * 1000).toLocaleString();

    if (!channelName || !setter) return;

    const tabId = `channel-${channelName}`;

    // Compose a new IrcLine for buffer rendering
    const bufferLine = cloneLine(line);
    bufferLine.command = line.command;
    bufferLine.raw = `Topic set by ${setter} on ${timestamp}`;

    client.opts.addUserLineTo?.(tabId, bufferLine);
};
