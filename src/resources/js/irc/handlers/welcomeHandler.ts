import type { IrcEventHandler } from '../types';

/**
 * Handles 001 (RPL_WELCOME) to extract and set the user's nickname.
 */
export const welcomeHandler: IrcEventHandler = (client, line) => {
    // Example raw: ":irc.aries 001 jesse_greathouse :Welcome to the network..."
    const nick = line.params[0];
    if (nick) {
        client.nick = nick;
    }
};
