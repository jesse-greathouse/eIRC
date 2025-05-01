import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const pingHandler: IrcEventHandler = async (client, line) => {
    if (line.command === 'PING') {
        await nextTick();
        const response = `→ PONG ${line.params.join(' ')}`;
        client.log(response);

        // Compose a new IrcLine for buffer rendering
        const bufferLine = cloneLine(line);
        bufferLine.command = 'PING';
        bufferLine.raw = response;

        client.opts.addUserLineTo?.('console', bufferLine);
    }
};
