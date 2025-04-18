import type { IrcEventHandler } from '../types';

export const privmsgHandler: IrcEventHandler = (client, line) => {
    const [target, message] = line.params;
    const sender = line.prefix?.split('!')[0] ?? 'unknown';

    if (!target || !message) return;

    // If the target starts with '#', it's a channel message
    if (target.startsWith('#')) {
        // Channel tab should already exist from JOIN, but you could verify here
        return;
    }

    // It's a PM to the user — sender is the tab we need
    client.opts.onPrivmsg?.(sender);
};
