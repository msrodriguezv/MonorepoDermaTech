import { Module, Logger } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule, JwtModuleOptions } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';
import { ClientsModule, Transport } from '@nestjs/microservices';

// --- Controllers ---
import { AuthController } from '../api/http/controllers/auth.controller';

// --- Command Handlers ---
import { RegisterUserCommandHandler } from '../application/commands/register-user/register-user.handler';
import { LoginHandler } from '../application/commands/login/login.handler';
import { LogoutHandler } from '../application/commands/logout/logout.handler';
import { RefreshTokenHandler } from '../application/commands/refresh-token/refresh-token.handler';

// --- Domain & Infrastructure ---
import { UserSchema } from '../infrastructure/persistence/typeorm/entities/user.schema';
import { TypeOrmUserRepository } from '../infrastructure/persistence/typeorm/repositories/typeorm-user.repository';

// --- Security Adapters & Strategies ---
import { BcryptAdapter } from './adapters/bcrypt.adapter';
import { JwtTokenAdapter } from './adapters/jwt-token.adapter';
import { MockUceAdapter } from './adapters/mock-uce.adapter';
import { KafkaEventPublisher } from '../infrastructure/messaging/kafka/publishers/kafka-event.publisher';
import { JwtStrategy, JwtAuthGuard } from '@dermatech/shared-guards';
import { SharedInfrasModule } from '@dermatech/shared-infras'; 

@Module({
  imports: [
    ConfigModule,
    CqrsModule,
    TypeOrmModule.forFeature([UserSchema]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    SharedInfrasModule, 

    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService): Promise<JwtModuleOptions> => {
        return {
          secret: configService.get<string>('JWT_SECRET'),
          signOptions: {
            expiresIn: configService.get('JWT_EXPIRES_IN') || '15m', 
          },
        };
      },
    }),

    ClientsModule.registerAsync([
      {
        name: 'AUTH_KAFKA_CLIENT',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => {
          // --- KAFKA CONNECTION DEBUGGING & VALIDATION ---
          const logger = new Logger('AuthModuleKafka');
          const brokers = configService.get<string>('KAFKA_BROKERS');
          const clientId = configService.get<string>('KAFKA_CLIENT_ID', 'auth-service');
          const groupId = configService.get<string>('KAFKA_GROUP_ID', 'auth-service-group');
 
          // This prevents the application from silently defaulting to localhost and failing later with connection refused.
          if (!brokers) {
            const errorMsg = 'CRITICAL ERROR: KAFKA_BROKERS environment variable is missing. Connection will fail.';
            logger.error(errorMsg);
            throw new Error(errorMsg);
          }

          logger.log(`Kafka Client Initialization: Connecting to Brokers at [${brokers}]`);

          return {
            transport: Transport.KAFKA,
            options: {
              client: {
                clientId: clientId,
                // We must strictly use the environment variable provided by Docker Compose (host.docker.internal).
                brokers: [brokers], 
                retry: { retries: 10, initialRetryTime: 300 },
              },
              producer: {
                idempotent: true,
                allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
              },
              consumer: {
                groupId: groupId,
                sessionTimeout: 30000,
                allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
              },
            },
          };
        },
      },
    ]),
  ],
  controllers: [AuthController],
  providers: [
    RegisterUserCommandHandler,
    LoginHandler,
    LogoutHandler,
    RefreshTokenHandler,
    JwtStrategy,
    JwtAuthGuard,

    { provide: 'UserRepositoryPort', useClass: TypeOrmUserRepository },
    { provide: 'ExternalSystemPort', useClass: MockUceAdapter },
    { provide: 'CryptoServicePort', useClass: BcryptAdapter },
    { provide: 'TokenServicePort', useClass: JwtTokenAdapter },
    { provide: 'EventPublisherPort', useClass: KafkaEventPublisher },

  ],
  exports: [
    JwtAuthGuard, 
    JwtModule, 
    PassportModule,
  ],
})
export class AuthModule {}