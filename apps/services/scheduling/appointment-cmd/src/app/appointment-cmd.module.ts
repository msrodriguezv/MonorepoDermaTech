import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
 
import { SharedAuthModule } from '@dermatech/shared-guards';
import { Doctor } from './entities/doctor.entity';
import { Appointment } from './entities/appointment.entity';
import { DoctorController } from './controllers/doctor.controller';
import { AppointmentController } from './controllers/appointment.controller';
import { BookAppointmentHandler } from './cqrs/commands/handlers/book-appointment.handler';
import { CreateDoctorHandler } from './cqrs/commands/handlers/create-doctor.handler';
import { TriagePatientHandler } from './cqrs/commands/handlers/triage-patient.handler';
import { GetStudentAppointmentsHandler } from './cqrs/queries/handlers/get-student-appointments.handler';
import { GetClinicalQueueHandler } from './cqrs/queries/handlers/get-clinical-queue.handler'; 
// --- EVENT HANDLERS (Infrastructure Bridge) ---
import { PublishAppointmentCreatedHandler } from './cqrs/events/handlers/publish-appointment-created.handler';


@Module({
  imports: [
    ConfigModule.forRoot({ 
      isGlobal: true,
    }),

    CqrsModule,       // Enables Command/Event/Query Bus
    SharedAuthModule, // Imports JWT Strategies and Guards

    // 3. Kafka Configuration (Event Output)
    ClientsModule.registerAsync([
      {
        name: 'KAFKA_SERVICE_APPOINTMENT', 
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.KAFKA,
          options: {
            client: {
              clientId: config.get<string>('KAFKA_CLIENT_ID', 'appointment-cmd'),
              brokers: config.get<string>('KAFKA_BROKERS', 'localhost:9092').split(','),
              retry: { retries: 10, initialRetryTime: 300 },
            },
            producer: {
              idempotent: true, 
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
        synchronize: true, 
      }),
    }),
    
    // Register Entities for this specific module scope
    TypeOrmModule.forFeature([Doctor, Appointment]),
  ],
  controllers: [
    DoctorController, 
    AppointmentController // Contains the endpoints for Triage and Queues
  ],
  providers: [
    // --- Command Handlers (Input Logic / Write) ---
    CreateDoctorHandler, 
    BookAppointmentHandler,
    TriagePatientHandler,  

    // --- Query Handlers (Read Logic / Views) ---
    GetClinicalQueueHandler, 
    GetStudentAppointmentsHandler, 

    // --- Event Handlers (Output Logic / Bridge) ---
    PublishAppointmentCreatedHandler 
  ],
})
export class AppointmentCmdModule {}