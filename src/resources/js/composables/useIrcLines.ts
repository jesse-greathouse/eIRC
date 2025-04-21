import { reactive } from 'vue';
import { IrcLine } from '@/types/IrcLine';
import { useChatTabs } from '@/composables/useChatTabs';

const _lines = reactive(new Map<string, IrcLine[]>());
const initialized = { value: false };

export function useIrcLines() {
  const { addChannelTab, addPrivmsgTab } = useChatTabs();

  if (!initialized.value) {
    _lines.set('console', []);
    initialized.value = true;
  }

  function ensureTabExists(target: string) {
    if (!_lines.has(target)) {
      if (target.startsWith('channel-')) {
        addChannelTab(target.slice(8));
      } else if (target.startsWith('pm-')) {
        addPrivmsgTab(target.slice(3));
      } else {
        console.warn(`[addLinesTo] Unknown tab type: "${target}"`);
      }

      _lines.set(target, []);
    }
  }

  function addLinesTo(target: string, newLines: IrcLine[]) {
    ensureTabExists(target);
    const existing = _lines.get(target) ?? [];
    _lines.set(target, [...existing, ...newLines]);
  }

  function addUserLineTo(tabId: string, line: IrcLine) {
    ensureTabExists(tabId);
    const existing = _lines.get(tabId) ?? [];
    _lines.set(tabId, [...existing, line]);
  }

  function getLinesFor(target: string) {
    return _lines.get(target) ?? [];
  }

  return {
    lines: _lines,
    addLinesTo,
    addUserLineTo,
    getLines: () => _lines,
    getLinesFor,
  };
}
