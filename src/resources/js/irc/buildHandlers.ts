import { IRC_EVENT_KEYS } from './constants';
import type { IrcEventHandler } from './types';

import { pingHandler } from './handlers/pingHandler';
import { joinHandler } from './handlers/joinHandler';
import { privmsgHandler } from './handlers/privmsgHandler';
import { welcomeHandler } from './handlers/welcomeHandler';

export function buildHandlers(): Record<string, IrcEventHandler[]> {
    return {
        [IRC_EVENT_KEYS.PING]: [pingHandler],
        [IRC_EVENT_KEYS.JOIN]: [joinHandler],
        [IRC_EVENT_KEYS.PRIVMSG]: [privmsgHandler],
        [IRC_EVENT_KEYS.WELCOME]: [welcomeHandler],
    };
}
