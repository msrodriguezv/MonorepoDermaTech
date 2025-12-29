import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // Esta variable vendrá del archivo .env
      // Opción A: Usar un valor de respaldo (Recomendada para que compile YA)
secretOrKey: configService.get<string>('JWT_SECRET') || 'secreto_tesis_fallback',});
  }

  async validate(payload: any) {
    // Si el token es válido, esto inyecta el usuario en el request
    if (!payload.sub) {
      throw new UnauthorizedException('Token inválido');
    }
    return { userId: payload.sub, email: payload.email, role: payload.role };
  }
}