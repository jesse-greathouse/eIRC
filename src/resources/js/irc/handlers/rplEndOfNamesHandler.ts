import type { IrcEventHandler } from '../types';
import { namesProcessingState } from './rplNameReplyHandler'; // Make sure this is exported
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const rplEndOfNamesHandler: IrcEventHandler = (client, line) => {
    const channelName = line.params[1];
    if (!channelName) return;

    // Finalize the NAMES list
    namesProcessingState.delete(channelName);

    const tabId = `channel-${channelName}`;
    const message = `End of user list for ${channelName}`;

    client.opts.addUserLineTo?.(tabId, new IrcLine({
        id: nanoid(),
        timestamp: Date.now(),
        raw: message,
        command: 'ENDOFNAMES',
        params: [channelName],
        prefix: 'server',
    }));

    client.log(`[366] Finished processing NAMES for ${channelName}`);
};
