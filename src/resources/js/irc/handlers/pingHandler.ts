import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

export const pingHandler: IrcEventHandler = async (client, line) => {
    if (line.command === 'PING') {
        await nextTick();
        const response = `→ PONG ${line.params.join(' ')}`;
        client.log(response);

        client.opts.addUserLineTo?.('console', new IrcLine({
            id: nanoid(),
            timestamp: Date.now(),
            raw: response,
            command: 'PING',
            params: ['', response],
        }));
    }
};
