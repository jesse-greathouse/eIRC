import type { IrcLine } from '@/types/IrcLine';
import { IRC_EVENT_KEYS } from '@/irc/constants';

export type ClassifiedLineType = 'message' | 'notice' | 'event' | 'server';

export function isFromServer(line: IrcLine): boolean {
    return line.prefix?.startsWith('irc.') ?? false;
}

export function classifyLine(line: IrcLine, context: 'console' | 'channel' | 'privmsg'): ClassifiedLineType {
    const { command } = line;

    const isEvent = [
        IRC_EVENT_KEYS.JOIN,
        IRC_EVENT_KEYS.PART,
        IRC_EVENT_KEYS.QUIT,
        IRC_EVENT_KEYS.MODE,
    ].includes(command);

    const isNotice = command === 'NOTICE';
    const isServerReply = [
        IRC_EVENT_KEYS.RPL_TOPIC,
        IRC_EVENT_KEYS.RPL_TOPICWHOTIME,
    ].includes(command);

    switch (context) {
        case 'console':
            return isNotice || isServerReply ? 'notice' : 'message';

        case 'channel':
            if (isEvent) return 'event';
            if (isNotice || isServerReply) return 'notice';
            return 'message';

        case 'privmsg':
            return command === IRC_EVENT_KEYS.PRIVMSG ? 'message' : 'notice';
    }
}
