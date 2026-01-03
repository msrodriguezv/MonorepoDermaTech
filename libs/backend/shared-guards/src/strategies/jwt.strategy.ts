import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { JwtPayload } from '../../../shared-dtos/src/interfaces/jwt-payload.interface'; 
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      // 1. Extract the token from the Authorization Header (Bearer ...)
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      
      // 2. Reject expired tokens immediately
      ignoreExpiration: false,
      
      // 3. Secret Key for verification. 
      // CRITICAL: This must match the key used to sign the token in AuthService.
      // In a real production environment, ensure 'JWT_SECRET' is set in your .env file.
      secretOrKey: process.env.JWT_SECRET || 'MySuperSecretKey123!', 
    });
  }

  /**
   * Validation callback.
   * This method is called after the signature and expiration have been verified.
   * The return value is injected into the request object (e.g., req.user).
   * * @param payload Decoded JWT payload
   */
  async validate(payload: JwtPayload) {
    if (!payload.sub) {
        throw new UnauthorizedException('Invalid token: Subject (sub) is missing.');
    }

    // We return a lightweight user object to be available in the Controllers
    return { 
        userId: payload.sub, 
        email: payload.email, 
        role: payload.role 
    };
  }
}