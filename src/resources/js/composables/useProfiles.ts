import { useClient } from '@/composables/useClient';
import { createModelStore } from '@/lib/createModelStore';
import type { Profile } from '@/types';

export function useProfiles() {
    const { coreApi } = useClient('core');

    const store = createModelStore<Profile>({
        resourceName: 'profile',
        apiClient: {
            get: (realname: string) => coreApi.getProfile(realname).then(res => res.data),
        },
    });

    return {
        getProfile: store.get,
        cache: store.cache,
    };
}
