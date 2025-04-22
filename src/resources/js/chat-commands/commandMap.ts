import { meCommand } from './me';
import { privmsgCommand } from './privmsg';
import { noticeCommand } from './notice';
import { joinCommand } from './join';
import { whoisCommand } from './whois';
import type { ChatCommandHandler } from './types';

export const commandMap: Record<string, ChatCommandHandler> = {
    ME: meCommand,
    PRIVMSG: privmsgCommand,
    MSG: privmsgCommand,       // alias for PRIVMSG
    NOTICE: noticeCommand,
    JOIN: joinCommand,
    WHOIS: whoisCommand,
};
