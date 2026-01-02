import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(private configService: ConfigService) {
    super({
      // Try to extract the token in three different ways to ensure success
      jwtFromRequest: ExtractJwt.fromExtractors([
        ExtractJwt.fromAuthHeaderAsBearerToken(),
        ExtractJwt.fromHeader('authorization'),
        (req) => req.headers['authorization'],
      ]),
      // FIX: Enforce token expiration validation for security (Requested by Copilot)
      ignoreExpiration: false, 
      
      // Load secret from environment variables
      secretOrKey: configService.get<string>('JWT_SECRET') || 'SUPER_SECRET_KEY_TESIS_2025',
    });
  }

  async validate(payload: any) {
    if (!payload.sub) {
       throw new UnauthorizedException('Invalid token');
    }
    // Return the data present in the JWT payload
    return { userId: payload.sub, name: payload.name, role: payload.role };
  }
}