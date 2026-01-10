import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

// Shared Libraries (Security)
import { SharedAuthModule } from '@dermatech/shared-guards';

// Infrastructure
import { RedisProvider } from './configs/redis.config';

// Features (We will create these files in the NEXT step)
import { AvailabilityController } from './controllers/availability.controller';
import { AppointmentCreatedHandler } from './cqrs/events/appointment-created.handler';

@Module({
  imports: [
    // 1. Load Environment Variables
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/services/scheduling/availability-qry/.env',
    }),

    // 2. Security Layer (JWT & Guards)
    SharedAuthModule,
  ],
  controllers: [
    AvailabilityController, // HTTP Endpoint
  ],
  providers: [
    RedisProvider,             // Database Connection
    AppointmentCreatedHandler, // Kafka Consumer
  ],
})
export class AppModule {}