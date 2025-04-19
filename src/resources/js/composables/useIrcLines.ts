import { ref, type Ref } from 'vue';
import { IrcLine } from '@/types/IrcLine';
import { useChatTabs } from '@/composables/useChatTabs';

export function useIrcLines() {
  const { addChannelTab, addPrivmsgTab } = useChatTabs();
  const _lines = ref(new Map<string, IrcLine[]>());

  _lines.value.set('console', []);

  function addLinesTo(target: string, newLines: IrcLine[]) {
    if (!_lines.value.has(target)) {
      if (target.startsWith('channel-')) {
        addChannelTab(target.slice(8));
      } else if (target.startsWith('pm-')) {
        addPrivmsgTab(target.slice(3));
      } else {
        console.warn(`[addLinesTo] Unknown tab type: "${target}"`);
      }

      _lines.value.set(target, []);
    }

    // Replace the array with a new one to trigger reactivity
    const existing = _lines.value.get(target) ?? [];
    _lines.value.set(target, [...existing, ...newLines]);
  }

  function getLinesFor(target: string) {
    return _lines.value.get(target) ?? [];
  }

 return {
    lines: _lines,
    addLinesTo,
    getLines: () => _lines.value,
    getLinesFor,
 };
}
