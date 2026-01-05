import { Test, TestingModule } from '@nestjs/testing';
import { RefreshTokenHandler } from './refresh-token.handler';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { RefreshTokenCommand } from './refresh-token.command';

describe('RefreshTokenHandler', () => {
  let handler: RefreshTokenHandler;

  // Mock Dependencies
  // We define the mocks externally to assert against them directly later.
  const mockJwtService = {
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks(); // Ensure clean state between tests

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RefreshTokenHandler,
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    handler = module.get<RefreshTokenHandler>(RefreshTokenHandler);
    // Removed unused 'jwtService' and 'configService' retrievals to satisfy linter.
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('execute', () => {
    const validRefreshToken = 'valid.refresh.token';
    const jwtSecret = 'super-secret';
    // Decoded payload structure matches JwtPayload interface
    const decodedPayload = { sub: '123', email: 'test@uce.edu.ec', role: 'STUDENT' };
    const newAccessToken = 'new.access.token';

    it('should return a new access token when refresh token is valid', async () => {
      // Arrange
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'JWT_SECRET') return jwtSecret;
        if (key === 'JWT_EXPIRES_IN') return '15m';
        return null;
      });
      mockJwtService.verifyAsync.mockResolvedValue(decodedPayload);
      mockJwtService.signAsync.mockResolvedValue(newAccessToken);

      const command = new RefreshTokenCommand(validRefreshToken);

      // Act
      const result = await handler.execute(command);

      // Assert
      // We assert directly against the mock objects
      expect(mockJwtService.verifyAsync).toHaveBeenCalledWith(validRefreshToken, { secret: jwtSecret });
      expect(mockJwtService.signAsync).toHaveBeenCalled();
      
      expect(result).toEqual({
        accessToken: newAccessToken,
        refreshToken: validRefreshToken,
        expiresIn: 900,
        user: {
          id: decodedPayload.sub,
          email: decodedPayload.email,
          role: decodedPayload.role,
        },
      });
    });

    it('should throw UnauthorizedException if refresh token is invalid or expired', async () => {
      // Arrange
      mockConfigService.get.mockReturnValue(jwtSecret);
      // Simulate JWT library throwing an error (e.g., token expired signature)
      mockJwtService.verifyAsync.mockRejectedValue(new Error('Token expired'));

      const command = new RefreshTokenCommand('invalid.token');

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw Error if JWT_SECRET is not configured', async () => {
      // Arrange
      mockConfigService.get.mockReturnValue(undefined); // Simulate missing env var

      const command = new RefreshTokenCommand(validRefreshToken);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow('FATAL: JWT_SECRET is not defined');
    });
  });
});