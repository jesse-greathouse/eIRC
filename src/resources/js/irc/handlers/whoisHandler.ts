import type { IrcEventHandler } from '../types';
import { Whois } from '../models/Whois';

export const whoisHandler: IrcEventHandler = (client, line) => {
    const code = line.command; // e.g., '311', '312', '317', '319', '318'
    const nick = line.params[1];
    const user = client.getOrCreateUser(nick);

    if (!user.whois) {
        user.whois = new Whois(nick);
    }

    switch (code) {
        case '311': { // WHOIS user
            const [, nick, , host] = line.params;
            const userName = `${nick}@${host}`;

            Object.assign(user.whois, {
                nick,
                host,
                user: userName,
            });
            break;
        }
        case '312': { // WHOIS server
            const [, , server, serverInfo] = line.params;
            Object.assign(user.whois, {
                server,
                serverInfo,
            });
            break;
        }
        case '317': { // WHOIS idle
            const [, , idleSeconds, signOnTime] = line.params;
            Object.assign(user.whois, {
                idleSeconds: parseInt(idleSeconds, 10),
                signOnTime: parseInt(signOnTime, 10),
            });
            break;
        }
        case '319': { // WHOIS channels
            const channelsString = line.params[2];
            const channels = channelsString?.split(' ') ?? [];
            user.whois.channels = channels;

            for (let ch of channels) {
                let mode = '';
                if (ch.startsWith('@')) {
                    mode = 'op';
                    ch = ch.slice(1);
                } else if (ch.startsWith('+')) {
                    mode = 'voice';
                    ch = ch.slice(1);
                }

                // Now ch is clean channel name
                const { channel } = client.addUserToChannel(nick, ch);

                if (mode === 'op') {
                    channel.ops.add(user);
                } else if (mode === 'voice') {
                    channel.voice.add(user);
                }
            }
            break;
        }
        case '318': { // WHOIS end
            client.log(`[318] WHOIS completed for ${nick}: ${user.whois?.serialize()}`);
            break;
        }
        default:
            client.log(`Unhandled WHOIS code: ${code}`);
    }
};
