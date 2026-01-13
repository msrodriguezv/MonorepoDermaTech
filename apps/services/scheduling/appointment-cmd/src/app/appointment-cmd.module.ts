import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';

// Shared Library Import (Security & Guards)
import { SharedAuthModule } from '@dermatech/shared-guards';

// Local Entities
import { Doctor } from './entities/doctor.entity';
import { Appointment } from './entities/appointment.entity';

// Controllers (Entry Points)
import { DoctorController } from './controllers/doctor.controller';
import { AppointmentController } from './controllers/appointment.controller';

// Command Handlers (Business Logic / Write Model)
import { BookAppointmentHandler } from './cqrs/commands/handlers/book-appointment.handler';
import { CreateDoctorHandler } from './cqrs/commands/handlers/create-doctor.handler';

// Event Handlers (Infrastructure Bridge / Kafka Producer)
import { PublishAppointmentCreatedHandler } from './cqrs/events/handlers/publish-appointment-created.handler';

/**
 * AppointmentCmdModule
 * * Responsibility: 
 * - Orchestrates the "Write Side" of the Scheduling Domain.
 * - Configures Database persistence (Postgres).
 * - Configures Message Broker connection (Kafka).
 * - Registers CQRS Handlers (Commands & Events).
 */
@Module({
  imports: [
    // 1. Global Configuration
    // Loads environment variables from the specific service file
    ConfigModule.forRoot({ 
      isGlobal: true,
      envFilePath: 'apps/services/scheduling/appointment-cmd/.env',
    }),

    // 2. Architecture & Security Layers
    CqrsModule,       // Enables Command/Event Bus
    SharedAuthModule, // Imports JWT Strategies and Guards

    // 3. Kafka Configuration (Event Output)
    // Registers the Kafka Client to emit Integration Events (e.g., to Availability Query Service)
    ClientsModule.registerAsync([
      {
        name: 'KAFKA_SERVICE_APPOINTMENT', // Injection Token used in PublishAppointmentCreatedHandler
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.KAFKA,
          options: {
            client: {
              clientId: config.get<string>('KAFKA_CLIENT_ID', 'appointment-cmd'),
              brokers: [config.get<string>('KAFKA_BROKER', 'localhost:9092')],
              retry: { retries: 10, initialRetryTime: 300 },
            },
            producer: {
              idempotent: true, // not duplicates
              allowAutoTopicCreation: config.get<string>('NODE_ENV') !== 'production',
            },
            consumer: {
              groupId: config.get<string>('KAFKA_GROUP_ID', 'appointment-service-group'),
              sessionTimeout: 30000,
              allowAutoTopicCreation: config.get<string>('NODE_ENV') !== 'production',
            },
          },
        }),
      },
    ]),

    // 4. Database Persistence Layer
    // Asynchronous configuration ensures Env Vars are loaded before connection
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'aws-1-us-east-1.pooler.supabase.com'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USER', 'postgres.ztmlnmfiewjqalrgyneb'),
        password: config.get<string>('DB_PASSWORD', 'DermaTechTesis2025PS'),
        database: config.get<string>('DB_NAME', 'postgres'),
        autoLoadEntities: true,
        synchronize: true, // WARNING: Set to false in Production
      }),
    }),
    
    // Register Entities for this specific module scope
    TypeOrmModule.forFeature([Doctor, Appointment]),
  ],
  controllers: [
    DoctorController, 
    AppointmentController
  ],
  providers: [
    // --- Command Handlers (Input Logic) ---
    CreateDoctorHandler, 
    BookAppointmentHandler,

    // --- Event Handlers (Output Logic / Bridge) ---
    PublishAppointmentCreatedHandler 
  ],
})
export class AppointmentCmdModule {}