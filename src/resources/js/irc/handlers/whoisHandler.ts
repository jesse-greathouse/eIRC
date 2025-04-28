import { nextTick } from 'vue';
import type { IrcEventHandler } from '../types';
import { Whois } from '../models/Whois';

export const whoisHandler: IrcEventHandler = async (client, line) => {
    await nextTick();
    const code = line.command; // e.g., '311', '312', '317', '319', '318'
    const nick = line.params[1];
    const user = client.getOrCreateUser(nick);

    if (!user.whois) {
        user.whois = new Whois(nick);
    }

    switch (code) {
        case '311': { // WHOIS user (strictly per IRC spec)
            const [, nick, username, host, , realName] = line.params;

            Object.assign(user.whois, {
                nick,
                user: username,
                host,
                realName,
            });

            // Sync the top-level User realName with WHOIS realName
            if (realName) {
                user.realName = realName;
                client.opts.onWhois?.(nick, realName);
            }

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
        case '313': { // WHOIS operator status
            user.whois.isOperator = true;
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
        case '301': { // WHOIS away
            const [, , awayMessage] = line.params;
            user.whois.away = awayMessage ?? null;
            break;
        }
        case '318': { // WHOIS end
            // Nothing to do here, but keeping it just in case we have a future use.
            // if (user.whois) console.log(user.whois.serialize());
            break;
        }
        default:
            client.log(`Unhandled WHOIS code: ${code}`);
    }
};
