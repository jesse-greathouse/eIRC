import { IRC_EVENT_KEYS } from './constants';
import type { IrcEventHandler } from './types';
import { pingHandler } from './handlers/pingHandler';

export function buildHandlers(): Record<string, IrcEventHandler[]> {
    return {
        [IRC_EVENT_KEYS.PING]: [pingHandler],
        // Add more modular handlers here
    };
}
