import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject } from '@nestjs/common';
import { LogoutCommand } from './logout.command';
import { CacheServicePort } from '../../ports/cache-service.port';

@CommandHandler(LogoutCommand)
export class LogoutHandler implements ICommandHandler<LogoutCommand> {
  constructor(
    // Injection using the Port Token (Dependency Inversion)
    @Inject('CacheServicePort') private readonly cacheService: CacheServicePort,
  ) {}

  async execute(command: LogoutCommand): Promise<void> {
    const { token } = command;
    
    // Standard cleanup: Remove "Bearer " prefix if present in the command payload
    const cleanToken = token.replace('Bearer ', '').trim();

    // Key definition for Redis
    const redisKey = `blacklist:${cleanToken}`;

    // TTL (Time To Live):
    // In a perfect world, we decode the token to find 'exp' - 'now'.
    // For simplicity/safety, we assume the max token duration (e.g., 1 hour = 3600s).
    const defaultTtl = 3600; 

    await this.cacheService.setBlacklist(redisKey, defaultTtl);
  }
}