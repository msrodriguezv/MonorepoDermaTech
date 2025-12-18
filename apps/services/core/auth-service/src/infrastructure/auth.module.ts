import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';
import { JwtModule } from '@nestjs/jwt';

// Controllers
import { AuthController } from '../api/http/controllers/auth.controller'; // (Lo crearemos en el sig paso)

// Domain & Application
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';

// Infrastructure (Adapters)
import { UserSchema } from './persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from './persistence/typeorm/repositories/typeorm-user.repository';
import { BcryptService } from './security/bcrypt.service';

@Module({
  imports: [
    CqrsModule,
    // Register the Schema in TypeORM for this module
    TypeOrmModule.forFeature([UserSchema]),
    // JWT Configuration (R5 Security)
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'dev_secret_key_change_in_prod',
      signOptions: { expiresIn: '1h' },
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