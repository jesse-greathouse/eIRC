import type { IrcLine } from '@/types/IrcLine';

export function getTabKey(line: IrcLine): string {
    const target = line.params[0];

    if (line.command === 'PRIVMSG') {
        if (target?.startsWith('#')) {
            return `channel-${target}`;
        } else {
            // If prefix exists, it's incoming; otherwise it's outgoing, use param[0]
            const user = line.prefix?.split('!')[0] ?? target ?? 'unknown';
            return `pm-${user}`;
        }
    }

    if (line.command === 'MODE' && target?.startsWith('#')) {
        return `channel-${target}`;
    }

    return 'console';
}
