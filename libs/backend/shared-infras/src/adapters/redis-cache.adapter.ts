// apps/services/core/auth-service/src/infrastructure/adapters/redis-cache.adapter.ts
import { Injectable, Inject, Logger } from '@nestjs/common';
import { Redis } from 'ioredis';
import { CacheServicePort } from '../ports/cache-service.port';

/**
 * Adapter: RedisCacheAdapter
 * * Layer: Infrastructure
 */
@Injectable()
export class RedisCacheAdapter implements CacheServicePort {
  private readonly logger = new Logger(RedisCacheAdapter.name);

  constructor(
    @Inject('REDIS_CLIENT') private readonly redisClient: Redis
  ) {}

  async setBlacklist(key: string, ttl: number): Promise<void> {
    // Redis 'SET' command with 'EX' (Expiration in seconds)
    await this.redisClient.set(key, 'true', 'EX', ttl);
    this.logger.log(`[Cache] Key added to blacklist: ${key.substring(0, 15)}... (TTL: ${ttl}s)`);
  }

  async isBlacklisted(key: string): Promise<boolean> {
    // Redis 'EXISTS' returns 1 if exists, 0 otherwise.
    const exists = await this.redisClient.exists(key);
    return exists === 1;
  }
}