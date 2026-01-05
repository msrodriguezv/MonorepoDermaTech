import { Test, TestingModule } from '@nestjs/testing';
import { LogoutHandler } from './logout.handler';
import { LogoutCommand } from './logout.command';
import { CacheServicePort } from '../../ports/cache-service.port';

describe('LogoutHandler', () => {
  let handler: LogoutHandler;
  let cacheServiceMock: CacheServicePort;

  beforeEach(async () => {
    // 1. Create a Mock for the Cache Port
    // We don't use real Redis here; we just spy on the function calls.
    const MockCacheService = {
      setBlacklist: jest.fn(), 
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LogoutHandler,
        {
          provide: 'CacheServicePort', // Matches the token used in Module
          useValue: MockCacheService,
        },
      ],
    }).compile();

    handler = module.get<LogoutHandler>(LogoutHandler);
    cacheServiceMock = module.get<CacheServicePort>('CacheServicePort');
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  it('should add the sanitized token to the blacklist with correct TTL', async () => {
    // Arrange
    const rawToken = 'Bearer eyJhbGciOiJIUz...';
    const expectedCleanToken = 'eyJhbGciOiJIUz...';
    const command = new LogoutCommand(rawToken);
    
    // Act
    await handler.execute(command);

    // Assert
    // Check if the port was called exactly once
    expect(cacheServiceMock.setBlacklist).toHaveBeenCalledTimes(1);
    
    // Check arguments: Key should be "blacklist:<token>" and TTL should be 3600
    expect(cacheServiceMock.setBlacklist).toHaveBeenCalledWith(
      `blacklist:${expectedCleanToken}`, 
      3600
    );
  });
});