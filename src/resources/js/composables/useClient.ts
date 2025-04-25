import { CoreApiClient } from '@/api/core/Client';

const clients: Record<string, any> = {};

export function useClient(key: 'core') {
    if (key === 'core') {
        if (!clients.core) {
            clients.core = new CoreApiClient();
        }
        return { coreApi: clients.core as CoreApiClient };
    }

    throw new Error(`API client for key "${key}" is not defined.`);
}
