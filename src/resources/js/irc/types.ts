import type { IrcClient } from './IrcClient';
import { IrcLine } from '@/types/IrcLine';

export type IrcEventHandler = (client: IrcClient, line: IrcLine) => void;
