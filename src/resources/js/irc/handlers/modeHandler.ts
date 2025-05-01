import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';

export const modeHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const [target, mode, modeTarget] = line.params;
    if (!target || !mode || !modeTarget) return;

    if (!target.startsWith('#')) return; // Only handle channel modes for now

    const { channel, user } = client.addUserToChannel(modeTarget, target);

    if (mode === '+o') {
        channel.ops.add(user);
    } else if (mode === '-o') {
        channel.ops.delete(user);
    }

    if (mode === '+v') {
        channel.voice.add(user);
    } else if (mode === '-v') {
        channel.voice.delete(user);
    }

    // Ensure they are in each other's sets (defensive sync)
    channel.addUser(user);
    user.addChannel(channel);

    // Refresh WHOIS for target.
    await client.whois(modeTarget);

    client.opts.onMode?.(modeTarget, target, mode);
};
