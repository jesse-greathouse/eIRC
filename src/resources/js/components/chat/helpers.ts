import type { IrcLine } from '@/types/IrcLine';

export type LineType = 'message' | 'notice' | 'event';

export function classifyLine(line: IrcLine, context: 'console' | 'channel' | 'privmsg'): LineType {
    const isNotice = line.command === 'NOTICE';
    const isPrivmsg = line.command === 'PRIVMSG';
    const isEvent = ['JOIN', 'PART', 'QUIT', 'MODE'].includes(line.command);

    if (context === 'console') {
        return isNotice ? 'notice' : 'message';
    }

    if (context === 'channel') {
        if (isEvent) return 'event';
        if (isNotice) return 'notice';
        return 'message';
    }

    return isPrivmsg ? 'message' : 'notice';
}

export function getUser(line: IrcLine): string {
    return line.prefix?.split('!')[0] ?? 'unknown';
}

export function renderEventText(line: IrcLine): string {
    if (line.command === 'MODE') {
        const user = getUser(line);
        const mode = line.params[1] ?? '';
        const target = line.params[2] ?? '';
        return `${user} sets mode ${mode} on ${target}`;
    }
    return line.raw;
}
