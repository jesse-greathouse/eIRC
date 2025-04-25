import { reactive } from 'vue';
import { useClient } from '@/composables/useClient';
import { getFromIndexedDB, saveToIndexedDB } from '@/lib/indexedDB';
import { isCacheExpired } from '@/lib/isCacheExpired';
import type { Profile } from '@/types';

const profiles = reactive(new Map<string, { profile: Profile, timestamp: number }>());

export function useProfiles() {
    const { coreApi } = useClient('core');

    async function getProfile(realname: string): Promise<Profile | null> {
        const cached = profiles.get(realname);
        if (cached && !isCacheExpired(cached.timestamp)) {
            return cached.profile;
        }

        const indexedDBProfile = await getFromIndexedDB(realname);
        if (indexedDBProfile && !isCacheExpired(indexedDBProfile.timestamp)) {
            profiles.set(realname, { profile: indexedDBProfile.profile, timestamp: Date.now() });
            return indexedDBProfile.profile;
        }

        try {
            const apiResponse = await coreApi.getProfile(realname);
            const apiProfile = apiResponse.data;

            const now = Date.now();
            profiles.set(realname, { profile: apiProfile, timestamp: now });
            await saveToIndexedDB(realname, { profile: apiProfile, timestamp: now });
            return apiProfile;
        } catch (err: any) {
            console.warn(`Profile lookup failed for "${realname}": ${err.message}`);
            return null;
        }
    }

    return { getProfile };
}
