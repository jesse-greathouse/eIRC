import type { IrcLine } from '@/types/IrcLine';
import { IRC_EVENT_KEYS } from '@/irc/constants';

export function getUser(line: IrcLine): string {
    if (line.command === IRC_EVENT_KEYS.RPL_TOPICWHOTIME) {
        return (line.params[2] ?? '').split('!')[0];
    }
    return line.prefix?.split('!')[0] ?? 'server';
}

export function renderEventText(line: IrcLine): string {
    if (line.command === IRC_EVENT_KEYS.MODE) {
        const user = getUser(line);
        const mode = line.params[1] ?? '';
        const target = line.params[2] ?? '';
        return `${user} sets mode ${mode} on ${target}`;
    }
    return line.raw;
}
