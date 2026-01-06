import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { LogoutCommand } from './logout.command';

// Ports
import { CacheServicePort } from '../../ports/cache-service.port';
import { UserRepositoryPort } from '../../ports/user.repository.port';

/**
 * Handler: LogoutHandler
 * Responsibility: Invalidates the user session by blacklisting the Access Token
 * and revoking the Refresh Token in the database.
 */
@CommandHandler(LogoutCommand)
export class LogoutHandler implements ICommandHandler<LogoutCommand> {
  private readonly logger = new Logger(LogoutHandler.name);

  constructor(
    @Inject('CacheServicePort') 
    private readonly cacheService: CacheServicePort,
    
    @Inject('UserRepositoryPort') 
    private readonly userRepository: UserRepositoryPort,

    private readonly jwtService: JwtService,
  ) {}

  async execute(command: LogoutCommand): Promise<void> {
    const { token } = command;
    
    // Standard cleanup: Remove "Bearer " prefix if present in the command payload
    const cleanToken = token.replace('Bearer ', '').trim();

    try {
      // 1. Database Cleanup (Kill the Refresh Token)
      // We decode the token to identify the user and nullify their stored refresh token hash.
      const decoded = this.jwtService.decode(cleanToken);
      
      // Type guard to ensure decoded token has a subject (user ID)
      if (decoded && typeof decoded === 'object' && 'sub' in decoded) {
        const userId = decoded.sub;
        const user = await this.userRepository.findById(userId);

        if (user) {
          // Setting the hash to null invalidates any existing refresh token for this user
          user.setRefreshTokenHash(null);
          await this.userRepository.save(user);
        }
      }
    } catch (error) {
      // If decoding fails, we log a warning but proceed to blacklist the token to ensure minimal security
      this.logger.warn(`Failed to revoke refresh token during logout: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }

    // 2. Redis Cleanup (Blacklist the Access Token)
    const redisKey = `blacklist:${cleanToken}`;

    // TTL (Time To Live):
    // We assume a safe default duration (e.g., 1 hour) to keep the token in the blacklist.
    const defaultTtl = 3600; 

    await this.cacheService.setBlacklist(redisKey, defaultTtl);
  }
}