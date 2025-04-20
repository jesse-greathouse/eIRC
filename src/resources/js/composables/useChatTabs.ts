import { ref, computed, type Ref } from 'vue';
import ConsolePane from '@/components/chat/ConsolePane.vue';
import ChannelPane from '@/components/chat/ChannelPane.vue';
import PrivmsgPane from '@/components/chat/PrivmsgPane.vue';
import type { ChatTab } from '@/types/chat';
import { useChannelTabs } from './useChannelTabs';
import { usePrivmsgTabs } from './usePrivmsgTabs';

export function useChatTabs() {
    const { channels, addChannel: rawAddChannel } = useChannelTabs();
    const { privmsgs, addPrivmsgUser: rawAddPrivmsgUser } = usePrivmsgTabs();

    const tabTargets = new Map<string, Ref<HTMLElement | null>>();

    function trackRef(id: string) {
        if (!tabTargets.has(id)) {
            tabTargets.set(id, ref<HTMLElement | null>(null));
        }
    }

    function addChannelTab(name: string) {
        const id = `channel-${name}`;
        trackRef(id);
        rawAddChannel(name);
    }

    function addPrivmsgTab(nick: string) {
        const id = `pm-${nick}`;
        trackRef(id);
        rawAddPrivmsgUser(nick);
    }

    const consoleTab: ChatTab = {
        id: 'console',
        label: 'Console',
        component: ConsolePane,
    };

    const chatTabs = computed<ChatTab[]>(() => [
        consoleTab,
        ...channels.value.map(channel => ({
            id: channel.id,
            label: channel.label,
            component: ChannelPane,
        })),
        ...privmsgs.value.map(pm => ({
            id: pm.id,
            label: pm.label,
            component: PrivmsgPane,
        })),
    ]);

    return {
        chatTabs,
        tabTargets,
        addChannelTab,
        addPrivmsgTab,
    };
}
