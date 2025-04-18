import { IrcLine } from '@/types/IrcLine';

export function getTabKey(line: IrcLine): string {
  if (line.command === 'PRIVMSG' && line.params[0]?.startsWith('#')) {
    return `channel-${line.params[0]}`;
  } else if (line.command === 'PRIVMSG') {
    return `pm-${line.prefix?.split('!')[0] || 'unknown'}`;
  }
  return 'console';
}
