import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule } from '@nestjs/config';
import { JwtStrategy } from '../strategies/jwt.strategy';

/**
 * Shared Auth Module.
 * Exports the Passport configuration and JWT Strategy to be consumed by microservices.
 */
@Module({
  imports: [
    ConfigModule,
    // Register the default strategy as 'jwt'
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
  providers: [JwtStrategy],
  exports: [PassportModule, JwtStrategy],
})
export class SharedAuthModule {}