import type { IrcLine } from '@/types/IrcLine';
import { IRC_EVENT_KEYS } from '@/irc/constants';

export type ClassifiedLineType = 'message' | 'notice' | 'event' | 'server' | 'action';

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
        IRC_EVENT_KEYS.KICK,
        IRC_EVENT_KEYS.NICK,
    ].includes(command);

    const isNotice = command === 'NOTICE';
    const isServerReply = [
        IRC_EVENT_KEYS.TOPIC,
        IRC_EVENT_KEYS.RPL_TOPIC,
        IRC_EVENT_KEYS.RPL_TOPICWHOTIME,
    ].includes(command);

    const isAction =
        command === 'ACTION' || (
            command === IRC_EVENT_KEYS.PRIVMSG &&
            /^\x01ACTION [\s\S]+?\x01$/.test(line.raw ?? '')
        );

    switch (context) {
        case 'console':
            return isNotice || isServerReply ? 'notice' : 'message';

        case 'channel':
            if (isAction) return 'action';
            if (isEvent) return 'event';
            if (isNotice || isServerReply) return 'notice';
            return 'message';

        case 'privmsg':
            if (isAction) return 'action';
            return command === IRC_EVENT_KEYS.PRIVMSG ? 'message' : 'notice';
    }
}
