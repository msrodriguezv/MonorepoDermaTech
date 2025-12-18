import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';
import { JwtModule, JwtModuleOptions } from '@nestjs/jwt';

// Controllers
import { AuthController } from '../api/http/controllers/auth.controller'; // (Lo crearemos en el sig paso)

// Domain & Application
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';

// Infrastructure (Adapters)
import { UserSchema } from './persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from './persistence/typeorm/repositories/typeorm-user.repository';
import { BcryptService } from './security/bcrypt.service';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    CqrsModule,
    // Register the Schema in TypeORM for this module
    TypeOrmModule.forFeature([UserSchema]),
    // JWT Configuration (R5 Security)
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      // FIX: Return type explicit
      useFactory: (configService: ConfigService): JwtModuleOptions => {
        const secret = configService.get<string>('JWT_SECRET');
        const expiresIn = configService.get<string>('JWT_EXPIRES_IN');

        if (!secret) {
          throw new Error('JWT_SECRET is not defined in environment variables. Please add JWT_SECRET to your .env file or environment configuration.');
        }

        return {
          secret: secret,
          signOptions: {
            // FIX: We deliberately use 'any' here because the 'ms' library types 
            // used by jsonwebtoken are incompatible with generic strings in strict mode.
            // We disable the linter rule just for this line to keep the rest of the code strict.
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            expiresIn: (expiresIn || '1h') as any,
          },
        };
      },
    }),
  ],
  controllers: [
    AuthController,
    // We will register the controller here in a moment
    // AuthController
  ],
  providers: [
    // Command Handlers
    RegisterUserCommandHandler,

    // Dependency Injection (Hexagonal wiring)
    // When the domain asks for 'UserRepositoryPort', provide 'TypeOrmUserRepository'
    {
      provide: 'UserRepositoryPort',
      useClass: TypeOrmUserRepository,
    },
    // When the domain asks for 'CryptoServicePort', provide 'BcryptService'
    {
      provide: 'CryptoServicePort',
      useClass: BcryptService,
    },
  ],
})
export class AuthModule {}
