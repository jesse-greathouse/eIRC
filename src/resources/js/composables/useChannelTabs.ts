// src/resources/js/composables/useChannelTabs.ts
import { ref } from 'vue';

interface ChannelTab {
    id: string;       // "channel-<name>"
    label: string;    // "#<name>"
    name: string;     // raw name (e.g. "general")
}

const channels = ref<ChannelTab[]>([]);

export function useChannelTabs() {

    function addChannel(name: string) {
        const id = `channel-${name}`;
        if (!channels.value.find(c => c.id === id)) {
            channels.value.push({ id, label: `#${name}`, name });
        }
    }

    function removeChannel(name: string) {
        const id = `channel-${name}`;
        channels.value = channels.value.filter(c => c.id !== id);
    }

    function getChannelTabs(): ChannelTab[] {
        return channels.value;
    }

    return {
        addChannel,
        removeChannel,
        getChannelTabs,
        channels,
    };
}
