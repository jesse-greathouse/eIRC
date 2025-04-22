export class Whois {
    nick: string;
    realName: string | null = null;
    user: string | null = null;
    host: string | null = null;
    server: string | null = null;
    serverInfo: string | null = null;
    idleSeconds: number | null = null;
    signOnTime: number | null = null;
    channels: string[] | null = null;

    constructor(nick: string, init?: Partial<Whois>) {
        this.nick = nick;
        Object.assign(this, init);
    }

    serialize() {
        return {
            nick: this.nick,
            realName: this.realName,
            user: this.user,
            host: this.host,
            server: this.server,
            serverInfo: this.serverInfo,
            idleSeconds: this.idleSeconds,
            signOnTime: this.signOnTime,
            channels: this.channels,
        };
    }

    toJson(): string {
        return JSON.stringify(this.serialize());
    }
}
