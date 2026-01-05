import { Test, TestingModule } from '@nestjs/testing';
import { RedisCacheAdapter } from './redis-cache.adapter';
import { Redis } from 'ioredis';

describe('RedisCacheAdapter', () => {
  let adapter: RedisCacheAdapter;
  let redisClientMock: Partial<Redis>;

  beforeEach(async () => {
    // 1. Create a Mock for the external Redis library
    redisClientMock = {
      set: jest.fn().mockResolvedValue('OK'), // Simulate Redis responding "OK"
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RedisCacheAdapter,
        {
          provide: 'REDIS_CLIENT', // Matches the token in AuthModule
          useValue: redisClientMock,
        },
      ],
    }).compile();

    adapter = module.get<RedisCacheAdapter>(RedisCacheAdapter);
  });

  it('should be defined', () => {
    expect(adapter).toBeDefined();
  });

  it('should call Redis SET command with correct expiration parameters', async () => {
    // Arrange
    const key = 'blacklist:abc-123';
    const ttl = 3600;

    // Act
    await adapter.setBlacklist(key, ttl);

    // Assert
    // Verify that the underlying Redis client was called with:
    // SET <key> "true" EX <ttl>
    expect(redisClientMock.set).toHaveBeenCalledWith(
      key, 
      'true', 
      'EX', 
      ttl
    );
  });
});