import { Injectable, UnauthorizedException, Logger, Inject } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { JwtPayload } from '@dermatech/shared-dtos';

// Import the Port interface from the Application layer
import { CacheServicePort } from '../ports/cache-service.port';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    private readonly configService: ConfigService,
    @Inject('CacheServicePort') private readonly cacheService: CacheServicePort,
  ) {
    const secret = configService.get<string>('JWT_SECRET');

    // Fail fast if security configuration is missing to prevent runtime errors
    if (!secret) {
      throw new Error('FATAL ERROR: JWT_SECRET is not defined in environment variables. Application cannot start.');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
      passReqToCallback: true, // Enables access to the raw Request object in the validate method
    });
  }

  /**
   * Validates the JWT payload and checks the revocation status against the cache.
   * This ensures that tokens invalidated via logout are rejected immediately.
   * * @param req - The Express Request object (strictly typed to avoid 'any').
   * @param payload - The decoded JWT payload.
   */
  async validate(req: Request, payload: JwtPayload) {
    // Extract the raw token string from the Authorization header to construct the blacklist key
    const rawToken = ExtractJwt.fromAuthHeaderAsBearerToken()(req);

    if (rawToken) {
        // Query the cache provider (Redis) to check if the token is blacklisted
        const isBlacklisted = await this.cacheService.isBlacklisted(`blacklist:${rawToken}`);
        
        if (isBlacklisted) {
            this.logger.warn(`Access attempted with blacklisted token for user: ${payload.sub}`);
            throw new UnauthorizedException('Token has been revoked');
        }
    }

    // Validate strict payload structure ensuring the subject exists
    if (!payload.sub) {
        this.logger.warn('Token validation failed: Missing subject (sub) in payload.');
        throw new UnauthorizedException('Invalid token: Subject (sub) is missing.');
    }

    // Return the user object which is attached to the Request object
    return { 
        sub: payload.sub,      
        userId: payload.sub,   
        email: payload.email, 
        role: payload.role 
    };
  }
}