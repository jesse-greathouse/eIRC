import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { namesProcessingState } from './rplNameReplyHandler'; // Make sure this is exported

export const rplEndOfNamesHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const channelName = line.params[1];
    if (!channelName) return;

    // Finalize the NAMES list
    namesProcessingState.delete(channelName);

    client.log(`[366] Finished processing NAMES for ${channelName}`);
};
