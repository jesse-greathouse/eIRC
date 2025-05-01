import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';

export const privmsgHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const [target, message] = line.params;
    const senderNick = line.prefix?.split('!')[0] ?? 'unknown';

    if (!target || !message) return;

    const sender = client.getOrCreateUser(senderNick);

    // If it's a channel message
    if (target.startsWith('#')) {
        const channel = client.getOrCreateChannel(target);
        channel.addUser(sender); // Just in case they aren't tracked yet
        sender.addChannel(channel);
        return;
    }

    // Refresh WHOIS for target.
    await client.whois(senderNick);

    // It's a private message
    client.opts.onPrivmsg?.(senderNick, message);
};
