import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';
import { RedisCacheAdapter } from './adapters/redis-cache.adapter';

/**
 * Shared Infrastructure Module.
 * Responsibility: Encapsulate infrastructure dependencies (Redis, Database Drivers, etc.)
 * to be reused across multiple microservices or shared modules.
 */
@Module({
  imports: [ConfigModule], // Required to access Environment Variables (REDIS_HOST, etc.)
  providers: [
    // 1. Redis Client Provider (The physical connection)
    {
      provide: 'REDIS_CLIENT',
      useFactory: (configService: ConfigService): Redis => {
        const host = configService.get<string>('REDIS_HOST') || 'localhost';
        const port = configService.get<number>('REDIS_PORT') || 6379;
        return new Redis({ host, port });
      },
      inject: [ConfigService],
    },
    // 2. Cache Adapter Provider (The logical implementation of the Port)
    {
      provide: 'CacheServicePort',
      useClass: RedisCacheAdapter,
    },
  ],
  // Export providers so consuming modules (like SharedAuthModule) can inject them
  exports: ['REDIS_CLIENT', 'CacheServicePort'],
})
export class SharedInfrasModule {}