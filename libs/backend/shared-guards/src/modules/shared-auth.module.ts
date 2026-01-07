import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule } from '@nestjs/config';
import { JwtStrategy } from '../strategies/jwt.strategy';
import { SharedInfrasModule } from '@dermatech/shared-infras';

/**
 * Shared Auth Module.
 * Exports the Passport configuration and JWT Strategy to be consumed by microservices.
 */
@Module({
  imports: [
    ConfigModule,
    // Register the default strategy as 'jwt'
    PassportModule.register({ defaultStrategy: 'jwt' }),
    // Imports infrastructure to satisfy JwtStrategy dependencies (Redis)
    SharedInfrasModule,
  ],
  providers: [JwtStrategy],
  exports: [PassportModule, JwtStrategy],
})
export class SharedAuthModule {}