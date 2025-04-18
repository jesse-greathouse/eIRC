import { ref } from 'vue';
import type { PrivmsgTab } from '@/types/chat';

const privmsgs = ref<PrivmsgTab[]>([]);

export function usePrivmsgTabs() {
    function addPrivmsgUser(nick: string) {
        const id = `pm-${nick}`;
        if (!privmsgs.value.find(p => p.id === id)) {
            privmsgs.value.push({ id, label: `Private: ${nick}`, nick });
        }
    }

    function removePrivmsgUser(nick: string) {
        const id = `pm-${nick}`;
        privmsgs.value = privmsgs.value.filter(p => p.id !== id);
    }

    function getPrivmsgTabs(): PrivmsgTab[] {
        return privmsgs.value;
    }

    return {
        addPrivmsgUser,
        removePrivmsgUser,
        getPrivmsgTabs,
        privmsgs,
    };
}
