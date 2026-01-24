import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

// Dependency Injection Token
export const REDIS_CLIENT = 'REDIS_CLIENT';

/**
 * Redis Provider Factory.
 * Establishes a direct, high-performance connection to Redis using 'ioredis'.
 * This is used for the Read Model (Availability Bitmaps).
 */
export const RedisProvider: Provider = {
  provide: REDIS_CLIENT,
  useFactory: (config: ConfigService) => {
    return new Redis({
      host: config.get<string>('REDIS_HOST', 'localhost'),
      port: config.get<number>('REDIS_PORT', 6379),
      password: config.get<string>('REDIS_PASSWORD'), // Optional
      lazyConnect: true,
      retryStrategy: (times) => Math.min(times * 50, 2000),
    });
  },
  inject: [ConfigService],
};