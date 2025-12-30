import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtPayload } from '@dermatech/shared-dtos';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // We use the same secret used to sign the Access Token
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  /**
   * Passport validates the signature automatically.
   * If valid, this method is called with the decoded JSON.
   * Whatever you return here gets attached to `req.user`.
   */
  async validate(payload: JwtPayload) {
    if (!payload.sub) {
      throw new UnauthorizedException('Invalid token payload');
    }
    
    // We return a clean object that ensures type safety in the Controllers
    return { 
      id: payload.sub, 
      email: payload.email, 
      role: payload.role 
    };
  }
}