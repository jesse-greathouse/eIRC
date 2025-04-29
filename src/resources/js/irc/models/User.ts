import { reactive } from 'vue';
import type { Channel } from './Channel';
import { Whois } from './Whois';

export class User {
    nick: string;
    realName?: string;
    channels: Set<Channel>;
    modes: Set<string>;
    whois: Whois;

    constructor(nick: string, whois?: Whois) {
        this.nick = nick;
        this.channels = new Set<Channel>();
        this.modes = new Set<string>();
        this.whois = whois ?? reactive(new Whois(nick));
    }

    addChannel(channel: Channel) {
        this.channels.add(channel);
    }

    removeChannel(channel: Channel) {
        this.channels.delete(channel);
    }

    serialize() {
        return {
            nick: this.nick,
            realName: this.realName,
            channels: Array.from(this.channels).map(c => c.name),
            modes: Array.from(this.modes),
            whois: this.whois.serialize(),
        };
    }

    toJson(): string {
        return JSON.stringify(this.serialize());
    }
}
