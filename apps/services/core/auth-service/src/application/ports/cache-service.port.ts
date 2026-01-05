import { CacheServicePort as SharedCachePort } from '@dermatech/shared-guards';

/**
 * Port: CacheServicePort
 * * Layer: Application (Port)
 * * Solution: We use a TYPE ALIAS instead of an empty interface.
 * * This satisfies the Linter (no empty {}) and the Architecture (local definition exists).
 */
export type CacheServicePort = SharedCachePort;