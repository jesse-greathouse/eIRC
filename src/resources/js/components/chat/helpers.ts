import type { IrcLine } from '@/types/IrcLine';
import { IRC_EVENT_KEYS } from '@/irc/constants';

export function getUser(line: IrcLine): string {
    if (line.command === IRC_EVENT_KEYS.RPL_TOPICWHOTIME) {
        return (line.params[2] ?? '').split('!')[0];
    }
    return line.prefix?.split('!')[0] ?? 'server';
}

export function renderEventText(line: IrcLine): string {
    const user = getUser(line);

    if (line.command === IRC_EVENT_KEYS.MODE) {
        const mode = line.params[1] ?? '';
        const target = line.params[2] ?? '';
        const isBan = mode.includes('+b');
        const text = `${user} sets mode ${mode} on ${target}`;
        return isBan ? `<span class="text-red-600">${text}</span>` : text;
    }

    if (line.command === IRC_EVENT_KEYS.KICK) {
        const channel = line.params[0] ?? '';
        const target = line.params[1] ?? '';
        const reason = line.params[2] ?? '';
        const text = `${user} kicked ${target} from ${channel}${reason ? ` (${reason})` : ''}`;
        return `<span class="text-red-700">${text}</span>`;
    }

    if (line.command === IRC_EVENT_KEYS.NICK) {
        const newNick = line.params[0] ?? '';
        return `${user} is now known as ${newNick}`;
    }

    return line.raw;
}
