import type { IrcEventHandler } from '../types';
import { IrcClient } from '../IrcClient';

export const pingHandler: IrcEventHandler = (client, line) => {
    if (line.command === 'PING') {
        const response = `PONG ${line.params.join(' ')}`;
        console.log('→', response);
    }
};
