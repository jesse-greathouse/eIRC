import { nanoid } from 'nanoid';
import { IrcLine } from '@/types/IrcLine';

export function parseIrcLine(raw: string): IrcLine {
  let prefix: string | null = null;
  let command = '';
  let params: string[] = [];

  const timestamp = Date.now();
  let rest = raw;

  if (raw.startsWith(':')) {
    const idx = raw.indexOf(' ');
    prefix = raw.slice(1, idx);
    rest = raw.slice(idx + 1);
  }

  const tokens = rest.split(' ');
  command = tokens.shift() || '';

  let trailingIdx = tokens.findIndex(t => t.startsWith(':'));
  if (trailingIdx !== -1) {
    const trailing = tokens.slice(trailingIdx).join(' ').slice(1);
    params = [...tokens.slice(0, trailingIdx), trailing];
  } else {
    params = tokens;
  }

  return new IrcLine({
    id: nanoid(),
    timestamp,
    raw,
    prefix,
    command,
    params,
  });
}
