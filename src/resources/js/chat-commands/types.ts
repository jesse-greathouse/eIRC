import type { IrcClient } from '@/irc/IrcClient';

export interface CommandContext {
    commandText: string;
    args: string[];
    rawInput: string;
    tabId: string;
    nick: string;
    target: string;
    client: IrcClient;
    inject: (tabId: string, line: any) => void;
}

export type ChatCommandHandler = (ctx: CommandContext) => Promise<void>;
