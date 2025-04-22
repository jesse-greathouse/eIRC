import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const rplTopicHandler: IrcEventHandler = (client, line) => {
    const channelName = line.params[1];
    const topic = line.params[2];

    if (!channelName || !topic) return;

    const channel = client.getOrCreateChannel(channelName);
    channel.setTopic(topic);

    const tabId = `channel-${channelName}`;
    const message = `Topic for ${channelName}: "${topic}"`;

    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'TOPIC',
        params: [channelName, topic],
        prefix: `server`,
    }));
};
