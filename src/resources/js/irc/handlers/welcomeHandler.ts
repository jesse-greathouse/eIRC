import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';

/**
 * Handles 001 (RPL_WELCOME) to extract and set the user's nickname.
 */
export const welcomeHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const nick = line.params[0];
    if (nick) {
        client.nick = nick;
        // Trigger API sync via onWelcome hook
        client.opts.onWelcome?.(nick);
    }
};
