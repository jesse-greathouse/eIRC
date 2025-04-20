import { IrcLine } from '@/types/IrcLine';
import type { IrcEventHandler, IrcClientOptions } from './types';
import { parseIrcLine } from '@/lib/parseIrcLine';

export class IrcClient {
    private eventHandlers = new Map<string, IrcEventHandler[]>();
    private joinedChannels = new Set<string>();
    private socket: WebSocket | null = null;

    public nick: string = '';

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
            const parsed = parseIrcLine(raw); // import this at the top
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

        this.log(`sending: ${raw}`);
        this.socket.send(raw);
    }

    async quit(): Promise<void> {
        await this.input(`/quit`);
        this.disconnect();
    }

    async channels(): Promise<void> {
        await this.input(`/channels`);
    }

    async users(channel: string): Promise<void> {
        await this.input(`/users ${channel}`);
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
        this.joinedChannels.add(name);
    }

    getChannels() {
        return Array.from(this.joinedChannels);
    }
}
