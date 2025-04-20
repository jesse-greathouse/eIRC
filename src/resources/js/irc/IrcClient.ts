import { IrcLine } from '@/types/IrcLine';
import type { IrcEventHandler, IrcClientOptions } from './types';

export class IrcClient {
    private eventHandlers = new Map<string, IrcEventHandler[]>();
    private joinedChannels = new Set<string>();

    public nick: string = '';

    constructor(
        public readonly log: (msg: string) => void, // Changed from private to public
        private readonly draw: (line: IrcLine) => void,
        public readonly opts: IrcClientOptions = {}
    ) {}

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
