import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule, JwtModuleOptions } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { Redis } from 'ioredis'; // 1. Import Redis Client Library

// --- Controllers ---
import { AuthController } from '../api/http/controllers/auth.controller';

// --- Command Handlers ---
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';
import { LoginHandler } from '../application/commands/login/login.handler';
import { LogoutHandler } from '../application/commands/logout/logout.handler';
import { RefreshTokenHandler } from '../application/commands/refresh-token/refresh-token.handler';

// --- Domain & Infrastructure (Persistence) ---
import { UserSchema } from '../infrastructure/persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from '../infrastructure/persistence/typeorm/repositories/typeorm-user.repository';

// --- Security Adapters & Strategies ---
import { BcryptAdapter } from './adapters/bcrypt.adapter';
import { JwtTokenAdapter } from './adapters/jwt-token.adapter';
import { MockUceAdapter } from './adapters/mock-uce.adapter';
import { KafkaEventPublisher } from '../infrastructure/messaging/kafka/publishers/kafka-event.publisher';
import { JwtStrategy, JwtAuthGuard } from '@dermatech/shared-guards';
import { RedisCacheAdapter } from './adapters/redis-cache.adapter';

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

    // JWT Configuration
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService): Promise<JwtModuleOptions> => {
        return {
          secret: configService.get<string>('JWT_SECRET'),
          signOptions: {
            // We use configService.get() without explicit generic typing here 
            // to allow TypeScript to accept the value as compatible with the JWT library.
            expiresIn: configService.get('JWT_EXPIRES_IN') || '15m', 
          },
        };
      },
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
    LogoutHandler,
    RefreshTokenHandler,

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
    {
      provide: 'CacheServicePort',
      useClass: RedisCacheAdapter, 
    },
    // --- Infrastructure: Cache & Session (Redis) ---
    // 2. Register Redis Client Provider
    {
      provide: 'REDIS_CLIENT', // Dependency Injection Token
      useFactory: (configService: ConfigService) => {
        return new Redis({
          // Host defaults to 'localhost' if env var is missing (e.g., local dev)
          // In Docker Compose, this should be 'dermatech_redis'
          host: configService.get<string>('REDIS_HOST') || 'localhost',
          port: configService.get<number>('REDIS_PORT') || 6379,
        });
      },
      inject: [ConfigService],
    },
  ],
  exports: [
    JwtAuthGuard, 
    JwtModule, 
    PassportModule,
    'REDIS_CLIENT' // 3. Export Redis Client for external usage if needed
  ],
})
export class AuthModule {}