export interface CacheServicePort {
  /**
   * Stores a token in the blacklist with a Time-To-Live.
   * @param key The redis key.
   * @param ttl Expiration time in seconds.
   */
  setBlacklist(key: string, ttl: number): Promise<void>;

  /**
   * Checks if a key exists in the blacklist.
   * @param key The redis key to check.
   * @returns true if the token is blacklisted.
   */
  isBlacklisted(key: string): Promise<boolean>;
}