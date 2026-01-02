import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';
import { ClientsModule, Transport } from '@nestjs/microservices';

// --- Controllers ---
import { AuthController } from '../api/http/controllers/auth.controller';

// --- Command Handlers ---
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';
import { LoginHandler } from '../application/commands/login/login.handler';

// --- Domain & Infrastructure (Persistence) ---
import { UserSchema } from '../infrastructure/persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from '../infrastructure/persistence/typeorm/repositories/typeorm-user.repository';

// --- Security Adapters & Strategies ---
import { BcryptAdapter } from './adapters/bcrypt.adapter';
import { JwtTokenAdapter } from './adapters/jwt-token.adapter';
import { MockUceAdapter } from './adapters/mock-uce.adapter';
import { KafkaEventPublisher } from '../infrastructure/messaging/kafka/publishers/kafka-event.publisher';
import { JwtStrategy, JwtAuthGuard } from '@dermatech/shared-guards';

@Module({
  imports: [
    // Configuration Module
    ConfigModule,

    // Command Query Responsibility Segregation
    CqrsModule,

    // TypeORM Feature for User Entity
    TypeOrmModule.forFeature([UserSchema]),

    // Passport Middleware
    PassportModule.register({ defaultStrategy: 'jwt' }),

    // JWT Configuration (Async)
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
    }),

    // Kafka Client Registration
    // Registers the 'AUTH_KAFKA_CLIENT' token required by KafkaEventPublisher
    ClientsModule.registerAsync([
      {
        name: 'AUTH_KAFKA_CLIENT',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.KAFKA,
          options: {
            client: {
              clientId: 'auth',
              brokers: [configService.get<string>('KAFKA_BROKERS') || 'localhost:9092'],
            },
            consumer: {
              groupId: 'auth-consumer',
            },
          },
        }),
      },
    ]),
  ],
  controllers: [AuthController],
  providers: [
    // --- Application Handlers ---
    RegisterUserCommandHandler,
    LoginHandler,

    // --- Security Strategies ---
    JwtStrategy,
    JwtAuthGuard,

    // --- Dependency Injection (Hexagonal Ports -> Adapters) ---
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
      useClass: BcryptAdapter,
    },
    {
      provide: 'TokenServicePort',
      useClass: JwtTokenAdapter,
    },
    {
      provide: 'EventPublisherPort',
      useClass: KafkaEventPublisher,
    },
  ],
  exports: [JwtAuthGuard, JwtModule, PassportModule],
})
export class AuthModule {}