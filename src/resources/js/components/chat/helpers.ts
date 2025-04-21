import type { IrcLine } from '@/types/IrcLine';

export type LineType = 'message' | 'notice' | 'event';

export function classifyLine(line: IrcLine, context: 'console' | 'channel' | 'privmsg'): LineType {
    const { command } = line;
    const isEvent = ['JOIN', 'PART', 'QUIT', 'MODE'].includes(command);
    const isNotice = command === 'NOTICE';
    const isPrivmsg = command === 'PRIVMSG';

    switch (context) {
        case 'console':
            return isNotice ? 'notice' : 'message';

        case 'channel':
            if (isEvent) return 'event';
            if (isNotice) return 'notice';
            return 'message';

        case 'privmsg':
            return isPrivmsg ? 'message' : 'notice';
    }
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
