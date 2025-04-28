import type { IrcClient } from './IrcClient';
import { IrcLine } from '@/types/IrcLine';

export type IrcEventHandler = (client: IrcClient, line: IrcLine) => void;

export interface IrcClientOptions {
    onJoinChannel?: (channel: string) => void;
    onPrivmsg?: (nick: string) => void;
    addUserLineTo?: (tabId: string, line: IrcLine) => void;
    onNick?: (oldNick: string, newNick: string) => void;
    onWelcome?: (nick: string) => void;
    onWhois?: (nick: string, realName: string) => void;
}
