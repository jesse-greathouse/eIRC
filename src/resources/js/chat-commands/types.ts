import type { IrcClient } from '@/irc/IrcClient';
import { IrcLine } from '@/types/IrcLine';

export interface CommandContext {
    commandText: string;
    args: string[];
    rawInput: string;
    tabId: string;
    nick: string;
    target: string;
    client: IrcClient;
    inject: (tabId: string, line: IrcLine) => void;
    switchTab?: (tabId: string) => void;
}

export type ChatCommandHandler = (ctx: CommandContext) => Promise<void>;
