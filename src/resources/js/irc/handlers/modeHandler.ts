import type { IrcEventHandler } from '../types';

export const modeHandler: IrcEventHandler = (client, line) => {
    const [target] = line.params;
    if (!target) return;

    // Ensure the channel is tracked
    if (target.startsWith('#')) {
        client.joinChannel(target);
    }
};
