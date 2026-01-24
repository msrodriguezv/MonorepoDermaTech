import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { UnauthorizedException, Logger, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TokenResponseDto, JwtPayload } from '@dermatech/shared-dtos';
import { RefreshTokenCommand } from './refresh-token.command';
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';

@CommandHandler(RefreshTokenCommand)
export class RefreshTokenHandler implements ICommandHandler<RefreshTokenCommand> {
  private readonly logger = new Logger(RefreshTokenHandler.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject('UserRepositoryPort') private readonly userRepository: UserRepositoryPort,
    @Inject('CryptoServicePort') private readonly cryptoService: CryptoServicePort,
  ) {}

  async execute(command: RefreshTokenCommand): Promise<TokenResponseDto> {
    const { refreshToken } = command;

    const refreshSecret = this.configService.get<string>('JWT_REFRESH_SECRET');
    const jwtSecret = this.configService.get<string>('JWT_SECRET');
    
    if (!refreshSecret || !jwtSecret) {
        throw new Error('Internal Configuration Error: JWT Secrets missing');
    }

    try {
      // 1. Verify incoming token
      const payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
        secret: refreshSecret,
      });

      // -----------------------------------------------------------------------
      // CRITICAL: Stateful Database Check (Logout & Reuse Protection)
      // -----------------------------------------------------------------------
      
      // A. Retrieve user from DB
      const user = await this.userRepository.findById(payload.sub);
      
      // B. Check if user exists AND has a valid refresh token stored
      // If 'currentRefreshTokenHash' is NULL, it means the user Logged Out.
      if (!user || !user.getCurrentRefreshTokenHash()) {
          this.logger.warn(`Refresh attempt blocked: User logged out or revoked. UserID: ${payload.sub}`);
          throw new UnauthorizedException('Session expired or revoked. Please login again.');
      }

      // C. Validate Token Ownership (Hash Comparison)
      // We check if the incoming token matches the one currently stored in DB.
      // If they don't match, it means the token is old (Reuse Attempt) or stolen.
      const isMatch = await this.cryptoService.compare(refreshToken, user.getRefreshTokenHash());
      
      if (!isMatch) {
          this.logger.warn(`Token Reuse Detected! Possible theft attempt for UserID: ${payload.sub}`);
          // In a high-security environment, you might want to revoke ALL tokens for this user here.
          throw new UnauthorizedException('Invalid refresh token.');
      }

      // 2. Prepare payload (Plain Object)
      const userPayload = {
        sub: payload.sub,
        email: payload.email,
        role: payload.role,
      };

      // 3. Get Expiration Config
      const accessExpiresIn = this.configService.get<string>('JWT_EXPIRES_IN') ?? '1h';
      const refreshExpiresIn = this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '7d';

      // 4. Generate NEW Access Token
      // CLEAN CODE FIX: Use 'Record<string, unknown>' instead of 'any'.
      // This explicitly tells TS that 'userPayload' is a valid object structure for JWT signing.
      const newAccessToken = await this.jwtService.signAsync(
        userPayload as Record<string, unknown>, 
        {
          secret: jwtSecret,
          expiresIn: accessExpiresIn,
        } as JwtSignOptions
      );

      // 5. Generate NEW Refresh Token
      const newRefreshToken = await this.jwtService.signAsync(
        userPayload as Record<string, unknown>, 
        {
          secret: refreshSecret,
          expiresIn: refreshExpiresIn,
        } as JwtSignOptions
      );

      // 6. Hash & Save
      const hashedRefreshToken = await this.cryptoService.hash(newRefreshToken);

      if (payload.sub) {
          await this.userRepository.updateRefreshToken(payload.sub, hashedRefreshToken);
      } else {
          throw new UnauthorizedException('Invalid token payload: missing subject');
      }

      // 7. Calculate response time
      const expiresInMs = this.parseExpirationToMs(accessExpiresIn);

      return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresIn: expiresInMs,
        user: {
          id: payload.sub,
          email: payload.email,
          role: payload.role,
        },
      };

    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Unknown error';
      this.logger.warn(`Rotation failed: ${msg}`);
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  private parseExpirationToMs(timeString: string): number {
    const value = parseInt(timeString.replace(/\D/g, ''), 10);
    if (isNaN(value)) return 3600000; 

    if (timeString.endsWith('s')) return value * 1000;
    if (timeString.endsWith('m')) return value * 60 * 1000;
    if (timeString.endsWith('h')) return value * 60 * 60 * 1000;
    if (timeString.endsWith('d')) return value * 24 * 60 * 60 * 1000;

    return value; 
  }
}