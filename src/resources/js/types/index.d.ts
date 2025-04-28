import type { PageProps } from '@inertiajs/core';
import type { LucideIcon } from 'lucide-vue-next';
import type { Config } from 'ziggy-js';

export interface Auth {
    user: User;
}

export interface BreadcrumbItem {
    title: string;
    href: string;
}

export interface NavItem {
    title: string;
    href: string;
    icon?: LucideIcon;
    isActive?: boolean;
}

export interface SharedData extends PageProps {
    name: string;
    quote: { message: string; author: string };
    auth: Auth;
    ziggy: Config & { location: string };
    sidebarOpen: boolean;
}

export interface User {
    id: number;
    name: string;
    nick: string;
    realname: string;
    email: string;
    avatar?: string;
    email_verified_at: string | null;
    created_at: string;
    updated_at: string;
    channels: array;
}

export interface Avatar {
    id: number;
    profile_id: number;
    base64_data: string; // Full data URI including 'data:image/...;base64,...'
    created_at: string;
    updated_at: string;
}

export interface ShallowUser {
    id: number;
    nick: string;
    realname: string;
}

export interface Profile {
    id: number;
    user_id: number;
    bio: string | null;
    timezone: string;
    x_link: string | null;
    instagram_link: string | null;
    tiktok_link: string | null;
    youtube_link: string | null;
    facebook_link: string | null;
    pinterest_link: string | null;
    created_at: string;
    updated_at: string;
    selected_avatar_id: number | null;
    selected_avatar?: Avatar | null;
    user?: ShallowUser;
}

export type BreadcrumbItemType = BreadcrumbItem;

export type { ChatTab, ChannelTab, PrivmsgTab } from './chat';

// Temporarily reverting to d.ts style until IDE resolution is fixed
// Don't export class-based types from here
// Instead, import them from their file as needed
// export type { IrcLine, IrcLineSerialized } from './IrcLine';
