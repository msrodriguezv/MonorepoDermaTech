import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';

// --- Controllers ---
import { AuthController } from '../api/http/controllers/auth.controller';

// --- Command Handlers ---
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';
import { LoginHandler } from '../application/commands/login/login.handler';
import { MockUceAdapter } from './adapters/mock-uce.adapter';

// --- Domain & Infrastructure (Persistence) ---
import { UserSchema } from '../infrastructure/persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from '../infrastructure/persistence/typeorm/repositories/typeorm-user.repository';

// --- Security Adapters & Strategies ---
import { BcryptService } from '../infrastructure/security/bcrypt.service';
import { JwtTokenService } from '../infrastructure/security/jwt-token.service';
import { JwtStrategy } from '../infrastructure/security/strategies/jwt.strategy';
import { JwtAuthGuard } from '../infrastructure/security/guards/jwt-auth.guard';

@Module({
  imports: [
    // 1. Configuration (Access to .env variables)
    ConfigModule,

    // 2. CQRS (Command/Query Bus)
    CqrsModule,

    // 3. Database (TypeORM Feature for User Entity)
    TypeOrmModule.forFeature([UserSchema]),

    // 4. Passport (Authentication Middleware)
    PassportModule.register({ defaultStrategy: 'jwt' }),

    // 5. JWT Configuration (Async to read from ConfigService)
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { 
          expiresIn: '15m', // Access Token default expiration
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    // --- Application Handlers (Business Logic) ---
    RegisterUserCommandHandler,
    LoginHandler,

    // --- Security Strategies & Guards ---
    JwtStrategy,
    JwtAuthGuard,

    // --- Dependency Injection (Hexagonal Ports -> Adapters) ---
    // Binding abstract Ports to concrete Infrastructure implementations
    {
      provide: 'UserRepositoryPort',
      useClass: TypeOrmUserRepository,
    },
    {
      provide: 'ExternalSystemPort',
      useClass: MockUceAdapter,
    },
    {
      provide: 'CryptoServicePort',
      useClass: BcryptService,
    },
    {
      provide: 'TokenServicePort',
      useClass: JwtTokenService, 
    },
  ],
  exports: [
    JwtAuthGuard, 
    JwtModule, 
    PassportModule
  ],
})
export class AuthModule {}