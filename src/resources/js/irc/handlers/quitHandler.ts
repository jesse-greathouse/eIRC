import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { IrcLine } from '@/types/IrcLine';
import { nanoid } from 'nanoid';

function cloneLine(line: IrcLine): IrcLine {
    return new IrcLine({ ...line.toObject(), id: nanoid(), timestamp: Date.now() });
}

export const quitHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const userNick = line.prefix?.split('!')[0];
    if (!userNick) return;

    let quitMsg = '';

    if (line.params?.length) {
        quitMsg += ': ';
        quitMsg += line.params.filter(str => typeof str === 'string') // Ensure it's a string
            .map(str => str.replace(/^"|"$/g, '')) // Remove leading/trailing quotes
            .join(' ');
    }

    const user = client.getOrCreateUser(userNick);

    for (const channel of user.channels) {
        channel.removeUser(user);
        const tabId = `channel-${channel.name}`;

        // Compose a new IrcLine for buffer rendering
        const bufferLine = cloneLine(line);
        bufferLine.command = line.command;
        bufferLine.raw = `${userNick} has quit ${quitMsg}`;

        client.opts.addUserLineTo?.(tabId, bufferLine);
    }

    client.users.delete(userNick);
};
