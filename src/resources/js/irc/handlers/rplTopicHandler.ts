import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const rplTopicHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[1];
    const topic = line.params[2];

    if (!channelName || !topic) return;

    const channel = client.getOrCreateChannel(channelName);
    channel.setTopic(topic);

    const tabId = `channel-${channelName}`;
    const bufferLine = cloneLine(line);
    bufferLine.command = line.command;
    bufferLine.raw = `Topic for ${channelName}: "${topic}"`;

    client.opts.addUserLineTo?.(tabId, bufferLine);
};
