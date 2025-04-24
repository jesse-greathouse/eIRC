import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const topicHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[0];
    const topic = line.params[1];
    if (!channelName || !topic) return;

    const channel = client.getOrCreateChannel(channelName);
    channel.setTopic(topic);

    const tabId = `channel-${channelName}`;
    const message = `Topic for ${channelName} is "${topic}"`;
    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'TOPIC',
        params: [channelName, topic],
        prefix: `server`,
    }));
};
