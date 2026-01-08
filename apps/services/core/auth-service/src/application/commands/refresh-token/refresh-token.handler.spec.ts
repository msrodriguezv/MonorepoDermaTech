import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RefreshTokenHandler } from './refresh-token.handler';
import { RefreshTokenCommand } from './refresh-token.command';
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { User } from '../../../domain/entities/user.entity';

describe('RefreshTokenHandler', () => {
  let handler: RefreshTokenHandler;
  let jwtService: JwtService;
  let configService: ConfigService;
  let userRepository: UserRepositoryPort;
  let cryptoService: CryptoServicePort;

  const TEST_USER_ID = '123';
  const TEST_EMAIL = 'test@uce.edu.ec';
  const TEST_ROLE = 'STUDENT';
  const OLD_REFRESH_TOKEN = 'old.refresh.token';
  const NEW_REFRESH_TOKEN = 'new.refresh.token';
  const NEW_ACCESS_TOKEN = 'new.access.token';
  const HASHED_NEW_TOKEN = 'hashed_new_token';
  const HASHED_OLD_TOKEN = 'hashed_old_token';
  const MOCK_JWT_SECRET = 'mock-jwt-secret';
  const MOCK_REFRESH_SECRET = 'mock-refresh-secret';
  const MOCK_JWT_EXPIRATION = '1h';
  const MOCK_REFRESH_EXPIRATION = '7d';

  const decodedPayload = { 
    sub: TEST_USER_ID, 
    email: TEST_EMAIL, 
    role: TEST_ROLE 
  };

  const mockUser = {
    id: TEST_USER_ID,
    email: TEST_EMAIL,
    getCurrentRefreshTokenHash: jest.fn().mockReturnValue(HASHED_OLD_TOKEN),
    getRefreshTokenHash: jest.fn().mockReturnValue(HASHED_OLD_TOKEN),
  } as unknown as User;

  beforeEach(async () => {
    const mockJwtService = {
      verifyAsync: jest.fn().mockResolvedValue(decodedPayload),
      signAsync: jest.fn()
        .mockResolvedValueOnce(NEW_ACCESS_TOKEN)
        .mockResolvedValueOnce(NEW_REFRESH_TOKEN),
    };

    const mockConfigService = {
      get: jest.fn().mockImplementation((key: string): string => {
        const configMap: Record<string, string> = {
          JWT_REFRESH_SECRET: MOCK_REFRESH_SECRET,
          JWT_SECRET: MOCK_JWT_SECRET,
          JWT_EXPIRES_IN: MOCK_JWT_EXPIRATION,
          JWT_REFRESH_EXPIRES_IN: MOCK_REFRESH_EXPIRATION,
        };
        return configMap[key] ?? '';
      }),
    };

    const mockUserRepository = {
      findById: jest.fn().mockResolvedValue(mockUser),
      updateRefreshToken: jest.fn().mockResolvedValue(undefined),
    };

    const mockCryptoService = {
      hash: jest.fn().mockResolvedValue(HASHED_NEW_TOKEN),
      compare: jest.fn().mockResolvedValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RefreshTokenHandler,
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: 'UserRepositoryPort', useValue: mockUserRepository },
        { provide: 'CryptoServicePort', useValue: mockCryptoService },
      ],
    }).compile();

    handler = module.get<RefreshTokenHandler>(RefreshTokenHandler);
    jwtService = module.get<JwtService>(JwtService);
    configService = module.get<ConfigService>(ConfigService);
    userRepository = module.get<UserRepositoryPort>('UserRepositoryPort');
    cryptoService = module.get<CryptoServicePort>('CryptoServicePort');
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('execute', () => {
    it('should implement Token Rotation: verify signature, check DB, rotate tokens', async () => {
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      const result = await handler.execute(command);

      expect(configService.get).toHaveBeenCalledWith('JWT_REFRESH_SECRET');
      expect(configService.get).toHaveBeenCalledWith('JWT_SECRET');
      
      expect(jwtService.verifyAsync).toHaveBeenCalledWith(
        OLD_REFRESH_TOKEN, 
        expect.objectContaining({ secret: MOCK_REFRESH_SECRET })
      );
      
      expect(userRepository.findById).toHaveBeenCalledWith(TEST_USER_ID);
      
      expect(cryptoService.compare).toHaveBeenCalledWith(
        OLD_REFRESH_TOKEN, 
        HASHED_OLD_TOKEN
      );
      
      expect(jwtService.signAsync).toHaveBeenCalledTimes(2);
      
      expect(cryptoService.hash).toHaveBeenCalledWith(NEW_REFRESH_TOKEN);
      expect(userRepository.updateRefreshToken).toHaveBeenCalledWith(
        TEST_USER_ID, 
        HASHED_NEW_TOKEN
      );

      expect(result).toEqual({
        accessToken: NEW_ACCESS_TOKEN,
        refreshToken: NEW_REFRESH_TOKEN,
        expiresIn: 3600000,
        user: {
          id: TEST_USER_ID,
          email: TEST_EMAIL,
          role: TEST_ROLE,
        },
      });
    });

    it('should throw UnauthorizedException if user is logged out (hash is null)', async () => {
      const loggedOutUser = { 
        ...mockUser, 
        getCurrentRefreshTokenHash: jest.fn().mockReturnValue(null),
        getRefreshTokenHash: jest.fn().mockReturnValue(null),
      } as unknown as User;
      
      jest.spyOn(userRepository, 'findById').mockResolvedValue(loggedOutUser);
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      await expect(handler.execute(command)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if token reuse is detected (hash mismatch)', async () => {
      jest.spyOn(cryptoService, 'compare').mockResolvedValue(false);
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      await expect(handler.execute(command)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if user does not exist in database', async () => {
      jest.spyOn(userRepository, 'findById').mockResolvedValue(null);
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      await expect(handler.execute(command)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if JWT verification fails', async () => {
      const verificationError = new Error('Token expired or invalid signature');
      jest.spyOn(jwtService, 'verifyAsync').mockRejectedValue(verificationError);
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      await expect(handler.execute(command)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw Error if JWT secrets are missing in configuration', async () => {
      jest.spyOn(configService, 'get').mockReturnValue('');
      const command = new RefreshTokenCommand(OLD_REFRESH_TOKEN);

      await expect(handler.execute(command)).rejects.toThrow(Error);
      await expect(handler.execute(command)).rejects.toThrow('Internal Configuration Error: JWT Secrets missing');
    });
  });
});