import { reactive } from 'vue';
import { IrcLine } from '@/types/IrcLine';
import { useChatTabs } from '@/composables/useChatTabs';

export function useIrcLines() {
  const { addChannelTab, addPrivmsgTab } = useChatTabs();
  const _lines = reactive(new Map<string, IrcLine[]>());

  _lines.set('console', []);

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
    getLines: () => _lines, // if you want a snapshot use new Map(_lines)
    getLinesFor,
  };
}
