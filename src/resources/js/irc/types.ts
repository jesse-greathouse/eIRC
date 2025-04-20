import type { IrcClient } from './IrcClient';
import { IrcLine } from '@/types/IrcLine';

export type IrcEventHandler = (client: IrcClient, line: IrcLine) => void;

export type IrcClientOptions = {
    onJoinChannel?: (channel: string) => void;
    onPrivmsg?: (nick: string) => void;
    addUserLineTo?: (tabId: string, line: IrcLine) => void;
};
