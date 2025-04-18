import { ref, shallowReactive, type Ref } from 'vue';
import { IrcLine } from '@/types/IrcLine';
import { useChatTabs } from '@/composables/useChatTabs';

export function useIrcLines() {
  const { addChannelTab, addPrivmsgTab } = useChatTabs();

  const lines: Record<string, Ref<IrcLine[]>> = shallowReactive({
    console: ref<IrcLine[]>([]),
  });

  function addLinesTo(target: string, newLines: IrcLine[]) {

    if (!lines[target]) {

        if (target.startsWith('channel-')) {
        addChannelTab(target.slice(8));
        } else if (target.startsWith('pm-')) {
        addPrivmsgTab(target.slice(3));
        } else {
            console.warn(`[addLinesTo] Unknown tab type: "${target}"`);
        }

        lines[target] = ref<IrcLine[]>([]);
    }

    if (!lines[target]) {
        throw new Error(`Failed to create lines[${target}]`);
    }

    lines[target].value.push(...newLines);
  }

  return {
    lines,
    addLinesTo,
    getLines: () => lines,
  };
}
