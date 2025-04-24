import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const rplTopicWhoTimeHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[1];
    const setter = line.params[2];
    const timestamp = new Date(parseInt(line.params[3] ?? '0') * 1000).toLocaleString();

    if (!channelName || !setter) return;

    const tabId = `channel-${channelName}`;
    const message = `Topic set by ${setter} on ${timestamp}`;

    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'TOPICWHOTIME',
        params: [channelName, setter, timestamp],
        prefix: `server`,
    }));
};
