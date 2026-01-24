import { Test, TestingModule } from '@nestjs/testing';
import { LogoutHandler } from './logout.handler';
import { LogoutCommand } from './logout.command';
import { JwtService } from '@nestjs/jwt';
import { CacheServicePort } from '@dermatech/shared-infras';
import { UserRepositoryPort } from '../../ports/user.repository.port';

describe('LogoutHandler', () => {
  let handler: LogoutHandler;
  let cacheService: CacheServicePort;
  let jwtService: JwtService;
  let userRepository: UserRepositoryPort;

  beforeEach(async () => {
    // Mocks defined as partial objects satisfying the interface requirements
    const mockCacheService = {
      setBlacklist: jest.fn(),
      isBlacklisted: jest.fn(),
    };

    const mockJwtService = {
      decode: jest.fn(),
    };

    const mockUserRepository = {
      updateRefreshToken: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LogoutHandler,
        {
          provide: 'CacheServicePort',
          useValue: mockCacheService,
        },
        {
          provide: 'UserRepositoryPort',
          useValue: mockUserRepository,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
      ],
    }).compile();

    handler = module.get<LogoutHandler>(LogoutHandler);
    
    // Retrieve dependencies with correct Types
    cacheService = module.get<CacheServicePort>('CacheServicePort');
    userRepository = module.get<UserRepositoryPort>('UserRepositoryPort');
    jwtService = module.get<JwtService>(JwtService);
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  it('should blacklist token in Redis AND clear refresh token in DB', async () => {
    // Arrange
    const cleanToken = 'eyJhbGciOiJIUz...';
    const rawToken = `Bearer ${cleanToken}`;
    const command = new LogoutCommand(rawToken);

    const nowSec = 10000;
    jest.spyOn(Date, 'now').mockReturnValue(nowSec * 1000);

    // Mock decode returning a partial object compatible with the expected payload
    jest.spyOn(jwtService, 'decode').mockReturnValue({
      sub: 'user-123',
      exp: nowSec + 3600, 
    });

    // Act
    await handler.execute(command);

    // Assert
    // 1. Verify Redis Blacklisting
    expect(cacheService.setBlacklist).toHaveBeenCalledWith(
      `blacklist:${cleanToken}`, 
      3600
    );

    // 2. Verify Database Revocation
    expect(userRepository.updateRefreshToken).toHaveBeenCalledWith(
      'user-123', 
      null
    );
  });
});