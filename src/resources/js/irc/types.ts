import type { IrcClient } from './IrcClient';
import { IrcLine } from '@/types/IrcLine';

export type IrcEventHandler = (client: IrcClient, line: IrcLine) => void;

export interface IrcClientOptions {
    onJoinChannel?: (channel: string) => void;
    onPrivmsg?: (nick: string, message: string) => void;
    onKick?: (nick: string, channel: string, message: string) => void;
    onPart?: (nick: string, channel: string, message: string) => void;
    onQuit?: (nick: string, message: string) => void;
    onMode?: (nick: string, channel: string, mode: string) => void;
    onTopic?: (topic: string, channel: string) => void;
    onNick?: (oldNick: string, newNick: string) => void;
    onWelcome?: (nick: string) => void;
    onWhois?: (nick: string, realName: string) => void;
    addUserLineTo?: (tabId: string, line: IrcLine) => void;
}
