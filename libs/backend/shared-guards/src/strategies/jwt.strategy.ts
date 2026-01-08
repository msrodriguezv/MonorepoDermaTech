import { Injectable, UnauthorizedException, Inject, Logger } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy, StrategyOptionsWithRequest } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { JwtPayload } from '@dermatech/shared-dtos'; 
import { CacheServicePort } from '@dermatech/shared-infras';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    private readonly configService: ConfigService,
    // Dependency Injection via Port Token
    @Inject('CacheServicePort') private readonly cacheService: CacheServicePort,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false, // Let Passport handle 'exp' check automatically first
      secretOrKey: configService.get<string>('JWT_SECRET'),
      passReqToCallback: true, // CRITICAL: Allows access to the Request object to get the raw token
    } as StrategyOptionsWithRequest);
  }

  /**
   * Validates the token and checks the Blacklist.
   * This runs on EVERY protected request.
   */
  async validate(req: Request, payload: JwtPayload) {
    // 1. Extract Raw Token
    const rawToken = ExtractJwt.fromAuthHeaderAsBearerToken()(req);

    if (!rawToken) {
        throw new UnauthorizedException('No token found in request.');
    }

    // 2. Validate Payload Structure
    if (!payload.sub) {
        this.logger.warn('Token validation failed: Missing subject (sub).');
        throw new UnauthorizedException('Invalid token: Subject is missing.');
    }

    // 3. CHECK REDIS BLACKLIST (The missing security layer)
    const blacklistKey = `blacklist:${rawToken}`;
    const isBlacklisted = await this.cacheService.isBlacklisted(blacklistKey);

    if (isBlacklisted) {
        this.logger.warn(`[Security] Blocked access for blacklisted token. User: ${payload.sub}`);
        throw new UnauthorizedException('Session logged out. Please login again.');
    }

    this.logger.debug(`[Security] Access granted for User: ${payload.sub}`);

    // 4. Return User context
    return { 
        sub: payload.sub,      
        userId: payload.sub,   
        email: payload.email, 
        role: payload.role 
    };
  }
}