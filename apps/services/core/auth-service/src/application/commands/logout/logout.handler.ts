import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { LogoutCommand } from './logout.command';
import { CacheServicePort } from '@dermatech/shared-infras';
import { UserRepositoryPort } from '../../ports/user.repository.port';

/**
 * Handler: LogoutHandler
 * Responsibility: Securely terminates a user session.
 * Strategy:
 * 1. Immediate invalidation via Redis Blacklist (for the Access Token).
 * 2. Persistent invalidation via Database (nullifying the Refresh Token).
 */
@CommandHandler(LogoutCommand)
export class LogoutHandler implements ICommandHandler<LogoutCommand> {
  private readonly logger = new Logger(LogoutHandler.name);

  constructor(
    // Dependency Injection: Cache Service for Redis operations
    @Inject('CacheServicePort') private readonly cacheService: CacheServicePort,
    // Dependency Injection: User Repository to update the database
    @Inject('UserRepositoryPort') private readonly userRepository: UserRepositoryPort,
    private readonly jwtService: JwtService,
  ) {}

  async execute(command: LogoutCommand): Promise<void> {
    const { token } = command;
    // Sanitize the token string
    const cleanToken = token.replace('Bearer ', '').trim();
    const redisKey = `blacklist:${cleanToken}`;

    try {
      // 1. Decode token to extract expiration (exp) and user ID (sub)
      // We do not verify signature here as we want to logout even if it's expired
      const decoded = this.jwtService.decode(cleanToken) as { exp?: number, sub?: string } | null;

      // 2. Blacklist Access Token in Redis
      if (decoded && decoded.exp) {
        const nowInSeconds = Math.floor(Date.now() / 1000);
        const ttl = decoded.exp - nowInSeconds;

        if (ttl > 0) {
          await this.cacheService.setBlacklist(redisKey, ttl);
          this.logger.log(`Token blacklisted via Redis. TTL: ${ttl}s`);
        }
      }

      // 3. Revoke Refresh Token in Database (Critical for Security & Tests)
      if (decoded && decoded.sub) {
        // Set current_refresh_token to null to prevent future token renewals
        await this.userRepository.updateRefreshToken(decoded.sub, null);
        this.logger.log(`Refresh token revoked in DB for user: ${decoded.sub}`);
      }

    } catch (error: unknown) {
       const msg = error instanceof Error ? error.message : 'Unknown error';
       this.logger.error(`Logout process failed: ${msg}`);
       // We log the error but do not throw, to ensure a smooth user experience
    }
  }
}