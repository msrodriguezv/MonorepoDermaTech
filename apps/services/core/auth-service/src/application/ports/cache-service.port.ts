/**
 * Port: CacheServicePort
 * * Layer: Application (Port)
 * * Responsibility: Abstract interface for caching operations (Redis, Memcached, etc.).
 * * Hexagonal Principle: The Application layer defines the contract, Infrastructure implements it.
 */
export interface CacheServicePort {
  /**
   * Adds a token to the blacklist to invalidate it.
   * @param key - The unique key (e.g., "blacklist:token_string")
   * @param ttl - Time To Live in seconds (duration until token expiration)
   */
  setBlacklist(key: string, ttl: number): Promise<void>;
}