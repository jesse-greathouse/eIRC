/**
 * Determines whether a cached value has expired.
 *
 * @param {number} timestamp - The timestamp when the cache was stored.
 * @param {number} ttl - Time-to-live in milliseconds (default: 5 minutes).
 * @returns {boolean} - True if expired, false if still valid.
 */
export function isCacheExpired(timestamp: number, ttl: number = 5 * 60 * 1000): boolean {
    return Date.now() - timestamp >= ttl;
}
