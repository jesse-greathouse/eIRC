import type { IrcEventHandler } from '../types';

// Track ongoing NAMES per channel
export const namesProcessingState = new Map<string, boolean>();

export const rplNameReplyHandler: IrcEventHandler = (client, line) => {
    const channelName = line.params[2];
    const namesList = line.params[3]?.trim().split(' ') ?? [];
    if (!channelName || namesList.length === 0) return;

    const channel = client.getOrCreateChannel(channelName);

    // If this is the first 353 for the channel, clear existing users
    if (!namesProcessingState.get(channelName)) {
        channel.users.clear();
        channel.ops.clear();
        channel.voice.clear();
        namesProcessingState.set(channelName, true); // Mark as "processing"
    }

    for (let name of namesList) {
        let mode = '';
        if (name.startsWith('@')) {
            mode = 'op';
            name = name.slice(1);
        } else if (name.startsWith('+')) {
            mode = 'voice';
            name = name.slice(1);
        }

        const { user, channel } = client.addUserToChannel(name, channelName);

        if (mode === 'op') {
            channel.ops.add(user);
        } else if (mode === 'voice') {
            channel.voice.add(user);
        }
    }

    // Optional log for debugging
    client.log(`[353] Users in ${channelName}: ${namesList.join(', ')}`);
};
