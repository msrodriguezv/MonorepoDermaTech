import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload } from '@dermatech/shared-dtos'; 

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(private configService: ConfigService) {
    const secret = configService.get<string>('JWT_SECRET');

    // FAIL FAST SECURITY:
    // If the JWT_SECRET is missing from the environment, we MUST stop the application immediately.
    // It is unsafe to start with a fallback or undefined secret.
    if (!secret) {
      throw new Error('FATAL ERROR: JWT_SECRET is not defined in environment variables. Application cannot start.');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false, 
      secretOrKey: secret, // TypeScript is happy because we guaranteed 'secret' exists above.
    });
  }

  async validate(payload: JwtPayload) {
    if (!payload.sub) {
        this.logger.warn('Token validation failed: Missing subject (sub) in payload.');
        throw new UnauthorizedException('Invalid token: Subject (sub) is missing.');
    }

    this.logger.log(`🔍 JWT Payload Decoded: ${JSON.stringify(payload)}`);

    return { 
        sub: payload.sub,      
        userId: payload.sub,   
        email: payload.email, 
        role: payload.role 
    };
  }
}