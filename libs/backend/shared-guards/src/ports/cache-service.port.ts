export interface CacheServicePort {
  setBlacklist(key: string, ttl: number): Promise<void>;
  isBlacklisted(key: string): Promise<boolean>;
}