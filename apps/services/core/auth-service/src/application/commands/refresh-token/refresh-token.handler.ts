import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TokenResponseDto, JwtPayload } from '@dermatech/shared-dtos';
import { RefreshTokenCommand } from './refresh-token.command';

/**
 * Handler: RefreshTokenHandler
 * Responsibility: Validates a Refresh Token and issues a new Access Token.
 * Security: Verifies signature and ensures strict type safety.
 */
@CommandHandler(RefreshTokenCommand)
export class RefreshTokenHandler implements ICommandHandler<RefreshTokenCommand> {
  private readonly logger = new Logger(RefreshTokenHandler.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async execute(command: RefreshTokenCommand): Promise<TokenResponseDto> {
    const { refreshToken } = command;

    /**
     * Retrieve JWT secret from environment configuration.
     * Fail fast if secret is not configured to prevent runtime security issues.
     */
    const refreshSecret = this.configService.get<string>('JWT_REFRESH_SECRET');
    const jwtSecret = this.configService.get<string>('JWT_SECRET');
    if (!refreshSecret && !jwtSecret) {
        throw new Error('FATAL: JWT_SECRET is not defined in environment variables.');
    }

    const secretToVerify = refreshSecret || jwtSecret;

    try {
      /**
       * Verify the refresh token's cryptographic signature and expiration.
       * This throws an error if the token is invalid, expired, or tampered with.
       * The generic type <JwtPayload> ensures type safety for the decoded payload.
       */
      const payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
        secret: secretToVerify,
      });

      /**
       * Construct a new payload for the access token.
       * We only include claims that are necessary for authorization.
       * This follows the principle of least privilege for JWT claims.
       */
      const newPayload = {
        sub: payload.sub,
        email: payload.email,
        role: payload.role,
      };

      /**
       * Retrieve token expiration configuration with a safe default fallback.
       * The nullish coalescing operator (??) ensures we always have a valid value.
       */
      const expiresInConfig = this.configService.get<string>('JWT_EXPIRES_IN') ?? '15m';

      /**
       * Type assertion using Parameters utility type to resolve TypeScript's overload ambiguity.
       * signAsync has multiple overloads; this forces the compiler to select the object-based signature.
       * Parameters<JwtService['signAsync']>[1] extracts the type of the second parameter.
       */
      const newAccessToken = await this.jwtService.signAsync(
        newPayload as Record<string, unknown>,
        {
          secret: jwtSecret,
          expiresIn: expiresInConfig,
        } as Parameters<JwtService['signAsync']>[1]
      );

      /**
       * Return the new access token while preserving the original refresh token.
       * The refresh token is reused until it expires or is explicitly revoked.
       */
      return {
        accessToken: newAccessToken,
        refreshToken: refreshToken,
        expiresIn: 900,
        user: {
          id: payload.sub,
          email: payload.email,
          role: payload.role,
        },
      };

    } catch (error: unknown) {
      /**
       * Type-safe error handling using type narrowing.
       * We check if the error is an Error instance before accessing its message property.
       */
      const errorMessage = error instanceof Error ? error.message : 'Unknown signature error';
      
      /**
       * Log the failure for security monitoring while avoiding logging the full token.
       * Only the last 5 characters are logged to aid debugging without exposing secrets.
       */
      this.logger.warn(`Refresh token failed for token ending in ...${refreshToken.slice(-5)}: ${errorMessage}`);
      
      /**
       * Throw a generic UnauthorizedException to avoid leaking implementation details.
       * Specific error messages could be exploited by attackers to probe the system.
       */
      throw new UnauthorizedException('Invalid or expired refresh token. Please login again.');
    }
  }
}