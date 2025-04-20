import type { IrcLine } from '@/types/IrcLine';

export function getTabKey(line: IrcLine): string {
    if (line.command === 'PRIVMSG' && line.params[0]?.startsWith('#')) {
        return `channel-${line.params[0]}`;
    } else if (line.command === 'PRIVMSG') {
        return `pm-${line.prefix?.split('!')[0] || 'unknown'}`;
    } else if (line.command === 'MODE' && line.params[0]?.startsWith('#')) {
        return `channel-${line.params[0]}`;
    }
    return 'console';
}
