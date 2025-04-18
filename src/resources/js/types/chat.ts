import type { Component } from 'vue';

export interface ChatTab {
    id: string;
    label: string;
    component: Component;
}

export interface ChannelTab {
    id: string;      // e.g. "channel-general"
    label: string;   // e.g. "#general"
    name: string;    // e.g. "general"
}

export interface PrivmsgTab {
    id: string;      // e.g. "pm-nick"
    label: string;   // e.g. "Private: nick"
    nick: string;    // e.g. "nick"
}
