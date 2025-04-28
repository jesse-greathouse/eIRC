import { IrcLine } from '@/types/IrcLine';
import { User } from './models/User';
import { Channel } from './models/Channel';
import type { IrcEventHandler, IrcClientOptions } from './types';
import { parseIrcLine } from '@/lib/parseIrcLine';

export class IrcClient {
    private eventHandlers = new Map<string, IrcEventHandler[]>();
    private socket: WebSocket | null = null;
    private ready: boolean = false;
    private batchQueue: ((client: IrcClient) => void)[] = [];

    public nick: string = '';
    public users: Map<string, User> = new Map();
    public channels: Map<string, Channel> = new Map();

    constructor(
        private readonly token: string,
        private readonly host: string,
        private readonly port: number,

        public readonly log: (msg: string) => void,
        private readonly draw: (line: IrcLine) => void,
        public readonly opts: IrcClientOptions = {}
    ) { }

    connect() {
        const url = `ws://${this.host}:${this.port}/?chat_token=${this.token}`;
        this.socket = new WebSocket(url);

        this.socket.onopen = () => {
            this.log('WebSocket connected');
        };

        this.socket.onmessage = (event) => {
            const raw = event.data;
            const parsed = parseIrcLine(raw);
            this.handleLine(parsed);
        };

        this.socket.onclose = () => {
            this.log('WebSocket disconnected');
        };

        this.socket.onerror = (err) => {
            console.error('WebSocket error:', err);
        };
    }

    async input(commandText: string): Promise<void> {
        const raw = `/input ${commandText}`;

        if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
            const err = new Error('Cannot send: WebSocket is not open');
            this.log(err.message);
            throw err;
        }

        this.log(`→ ${commandText}`);
        this.socket.send(raw);
    }

    async fetchChannelList(): Promise<void> {
        const raw = `/channels`;

        if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
            const err = new Error('Cannot send: WebSocket is not open');
            this.log(err.message);
            throw err;
        }

        this.log(`→ ${raw}`);
        this.socket.send(raw);
    }

    async fetchUserList(channel: Channel): Promise<void> {
        const raw = `/users ${channel.name}`;

        if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
            const err = new Error('Cannot send: WebSocket is not open');
            this.log(err.message);
            throw err;
        }

        this.log(`→ ${raw}`);
        this.socket.send(raw);
    }

    async quit(): Promise<void> {
        const raw = `/quit`;

        if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
            const err = new Error('Cannot send: WebSocket is not open');
            this.log(err.message);
            throw err;
        }

        this.log(`→ ${raw}`);
        this.socket.send(raw);

        this.disconnect();
    }

    async msg(target: string, message: string): Promise<void> {
        return this.input(`PRIVMSG ${target} :${message}`);
    }

    async action(target: string, message: string): Promise<void> {
        return this.input(`PRIVMSG ${target} :\x01ACTION ${message}\x01`);
    }

    async join(channel: string): Promise<void> {
        return this.input(`JOIN ${channel}`);
    }

    async part(channel: string, message?: string): Promise<void> {
        return this.input(`PART ${channel}${message ? ` :${message}` : ''}`);
    }

    async notice(target: string, message: string): Promise<void> {
        return this.input(`NOTICE ${target} :${message}`);
    }

    async whois(target: string): Promise<void> {
        return this.input(`WHOIS ${target}`);
    }

    disconnect() {
        if (this.socket) {
            this.socket.close();
            this.socket = null;
        }
    }

    addEventHandler(event: string, handler: IrcEventHandler) {
        if (!this.eventHandlers.has(event)) {
            this.eventHandlers.set(event, []);
        }
        this.eventHandlers.get(event)!.push(handler);
    }

    handleLine(line: IrcLine) {
        const handlers = this.eventHandlers.get(line.command);
        if (handlers) {
            handlers.forEach(fn => fn(this, line));
        }

        // Default behavior: just log and display
        this.log(`[${line.command}] ${line.raw}`);
        this.draw(line);
    }

    joinChannel(name: string) {
        if (!this.channels.has(name)) {
            this.channels.set(name, new Channel(name));
        }
    }

    getChannelNames(): string[] {
        return Array.from(this.channels.keys());
    }

    getUser(nick?: string): User | null {
        if (!nick) return null;
        return this.users.get(nick) ?? null;
    }

    getOrCreateUser(nick: string): User {
        let user = this.users.get(nick);
        if (!user) {
            user = new User(nick);
            this.users.set(nick, user);
        }

        return user;
    }

    getOrCreateChannel(name: string): Channel {
        let channel = this.channels.get(name);
        if (!channel) {
            channel = new Channel(name);
            this.channels.set(name, channel);
        }
        return channel;
    }

    addUserToChannel(userNick: string, channelName: string): { user: User, channel: Channel } {
        const user = this.getOrCreateUser(userNick);
        const channel = this.getOrCreateChannel(channelName);

        // Link user to channel and vice versa
        user.addChannel(channel);
        channel.addUser(user);

        return { user, channel };
    }

    setReady(ready: boolean): void {
        this.ready = ready;

        if (ready) {
            while (this.batchQueue.length > 0) {
                const task = this.batchQueue.shift();

                if (task) {
                    try {
                        task(this);
                    } catch (err) {
                        console.error(`[IrcClient] Error executing task:`, err);
                    }
                } else {
                    console.warn(`[IrcClient] Encountered undefined task in batchQueue.`);
                }
            }
        }
    }

    isReady(): boolean {
        return this.ready;
    }

    onReady(tasks: ((client: IrcClient) => void)[]): void {
        if (this.ready) {
            // Execute immediately if ready
            tasks.forEach(task => task(this));
        } else {
            // Queue tasks for later
            this.batchQueue.push(...tasks);
        }
    }

    serialize(): object {
        const usersSerialized = Array.from(this.users.entries()).reduce((acc, [nick, user]) => {
            acc[nick] = user.serialize();
            return acc;
        }, {} as Record<string, object>);

        const channelsSerialized = Array.from(this.channels.entries()).reduce((acc, [name, channel]) => {
            acc[name] = channel.serialize();
            return acc;
        }, {} as Record<string, object>);

        return {
            nick: this.nick,
            users: usersSerialized,
            channels: channelsSerialized,
        };
    }

    toJson(pretty: boolean = false): string {
        return JSON.stringify(this.serialize(), null, pretty ? 2 : 0);
    }
}
