import { Injectable, Inject, Logger } from '@nestjs/common';
import { Redis } from 'ioredis';
import { CacheServicePort } from '../../application/ports/cache-service.port';

/**
 * Adapter: RedisCacheAdapter
 * * Layer: Infrastructure
 * * Responsibility: Concrete implementation of CacheServicePort using Redis.
 */
@Injectable()
export class RedisCacheAdapter implements CacheServicePort {
  private readonly logger = new Logger(RedisCacheAdapter.name);

  constructor(
    @Inject('REDIS_CLIENT') private readonly redisClient: Redis
  ) {}

  async setBlacklist(key: string, ttl: number): Promise<void> {
    // Redis 'SET' command with 'EX' (Expiration in seconds)
    // We store a simple string 'true' as the value, the importance is the Key existence.
    await this.redisClient.set(key, 'true', 'EX', ttl);
    
    this.logger.log(`[Cache] Key added to blacklist: ${key.substring(0, 15)}... (TTL: ${ttl}s)`);
  }
}