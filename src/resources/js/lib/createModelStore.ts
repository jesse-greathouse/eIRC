import { reactive } from 'vue';
import { getFromIndexedDB, saveToIndexedDB } from '@/lib/indexedDB';
import { isCacheExpired } from '@/lib/isCacheExpired';

interface StoreOptions<T> {
    resourceName: string;
    apiClient: {
        get: (key: string) => Promise<T>;
    };
    cacheDurationMs?: number;
}

export function createModelStore<T>(options: StoreOptions<T>) {
    const cache = reactive(new Map<string, { record: T; timestamp: number }>());

    const cacheDuration = options.cacheDurationMs ?? 5 * 60 * 1000;

    async function get(key: string): Promise<T | null> {
        const cached = cache.get(key);
        if (cached && !isCacheExpired(cached.timestamp, cacheDuration)) {
            // @ts-expect-error – Compiler issue with the next line for some reason...
            return cached.record;
        }

        const dbRecord = await getFromIndexedDB(`${options.resourceName}:${key}`);
        if (dbRecord && !isCacheExpired(dbRecord.timestamp, cacheDuration)) {
            // @ts-expect-error – ignore weird typing issues.
            cache.set(key, { record: dbRecord.record as T, timestamp: Date.now() });
            return dbRecord.record as T;
        }

        try {
            const apiRecord = await options.apiClient.get(key);
            const now = Date.now();
            // @ts-expect-error – ignore weird typing issues.
            cache.set(key, { record: apiRecord, timestamp: now });
            await saveToIndexedDB(`${options.resourceName}:${key}`, { record: apiRecord, timestamp: now });
            return apiRecord;
        } catch (err: any) {
            console.warn(`Failed to fetch ${options.resourceName} for key "${key}": ${err.message}`);
            return null;
        }
    }

    return { get, cache };
}
