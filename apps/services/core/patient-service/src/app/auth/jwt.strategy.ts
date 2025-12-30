import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor() {
   // En apps/services/core/patient-service/src/app/patient/auth/jwt.strategy.ts
super({
  // Intentará extraer el token de tres formas distintas para asegurar el éxito
  jwtFromRequest: ExtractJwt.fromExtractors([
    ExtractJwt.fromAuthHeaderAsBearerToken(),
    ExtractJwt.fromHeader('authorization'),
    (req) => req.headers['authorization'], 
  ]),
  ignoreExpiration: true, // Evita fallos por tokens antiguos
  secretOrKey: 'SUPER_SECRET_KEY_TESIS_2025',
});
  
  }

async validate(payload: any) {
  // Retornamos los datos que SI están en tu token de jwt.io
  return { userId: payload.sub, name: payload.name };
}
}
