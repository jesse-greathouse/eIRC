import { IRC_EVENT_KEYS } from './constants';
import type { IrcEventHandler } from './types';

import { pingHandler } from './handlers/pingHandler';
import { joinHandler } from './handlers/joinHandler';
import { privmsgHandler } from './handlers/privmsgHandler';
import { welcomeHandler } from './handlers/welcomeHandler';
import { modeHandler } from './handlers/modeHandler';

import { partHandler } from './handlers/partHandler';
import { quitHandler } from './handlers/quitHandler';
import { kickHandler } from './handlers/kickHandler';
import { nickHandler } from './handlers/nickHandler';
import { topicHandler } from './handlers/topicHandler';
import { rplNameReplyHandler } from './handlers/rplNameReplyHandler';

import { rplTopicHandler } from './handlers/rplTopicHandler';
import { rplTopicWhoTimeHandler } from './handlers/rplTopicWhoTimeHandler';
import { rplEndOfNamesHandler } from './handlers/rplEndOfNamesHandler';
import { motdHandler } from './handlers/motdHandler';

import { whoisHandler } from './handlers/whoisHandler';

export function buildHandlers(): Record<string, IrcEventHandler[]> {
    return {
        [IRC_EVENT_KEYS.PING]: [pingHandler],
        [IRC_EVENT_KEYS.JOIN]: [joinHandler],
        [IRC_EVENT_KEYS.PART]: [partHandler],
        [IRC_EVENT_KEYS.QUIT]: [quitHandler],
        [IRC_EVENT_KEYS.KICK]: [kickHandler],
        [IRC_EVENT_KEYS.NICK]: [nickHandler],
        [IRC_EVENT_KEYS.TOPIC]: [topicHandler],
        [IRC_EVENT_KEYS.PRIVMSG]: [privmsgHandler],
        [IRC_EVENT_KEYS.WELCOME]: [welcomeHandler],
        [IRC_EVENT_KEYS.MODE]: [modeHandler],

        //MOTD
        [IRC_EVENT_KEYS.MOTD_START]: [motdHandler],
        [IRC_EVENT_KEYS.MOTD_LINE]: [motdHandler],
        [IRC_EVENT_KEYS.MOTD_END]: [motdHandler],

        // RPL
        [IRC_EVENT_KEYS.RPL_NAMEREPLY]: [rplNameReplyHandler],
        [IRC_EVENT_KEYS.RPL_ENDOFNAMES]: [rplEndOfNamesHandler],
        [IRC_EVENT_KEYS.RPL_TOPIC]: [rplTopicHandler],
        [IRC_EVENT_KEYS.RPL_TOPICWHOTIME]: [rplTopicWhoTimeHandler],

        // WHOIS numerics
        [IRC_EVENT_KEYS.RPL_WHOISUSER]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_WHOISSERVER]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_WHOISIDLE]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_ENDOFWHOIS]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_WHOISCHANNELS]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_WHOISAWAY]: [whoisHandler],
        [IRC_EVENT_KEYS.RPL_WHOISOPERATOR]: [whoisHandler],
    };
}
