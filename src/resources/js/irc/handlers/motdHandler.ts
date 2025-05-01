import { IRC_EVENT_KEYS } from '@/irc/constants';
import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const motdHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const motdLine = line.params[1] ?? '';
    const tabId = 'console';

    // Compose a new IrcLine for buffer rendering
    const bufferLine = cloneLine(line);
    bufferLine.command = line.command;
    bufferLine.raw = `[MOTD] ${motdLine}`;

    client.opts.addUserLineTo?.(tabId, bufferLine);

    // Detect end of MOTD and mark client ready
    if (line.command === IRC_EVENT_KEYS.MOTD_END) {
        client.log('[Client Ready] MOTD complete, client will handle batch commands...');
        client.setReady(true);
    }
};
