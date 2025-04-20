import { meCommand } from './me';
// import { privmsgCommand } from './privmsg';
// import { noticeCommand } from './notice';
import type { ChatCommandHandler } from './types';

export const commandMap: Record<string, ChatCommandHandler> = {
    ME: meCommand,
    // PRIVMSG: privmsgCommand,
    // NOTICE: noticeCommand,
};
