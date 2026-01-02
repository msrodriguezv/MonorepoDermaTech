import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { JwtStrategy } from './jwt.strategy';

/**
 * Shared Auth Module.
 * Exports the Passport configuration and JWT Strategy to be consumed by microservices.
 */
@Module({
  imports: [
    // Register the default strategy as 'jwt'
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
  providers: [JwtStrategy],
  exports: [PassportModule, JwtStrategy],
})
export class SharedAuthModule {}