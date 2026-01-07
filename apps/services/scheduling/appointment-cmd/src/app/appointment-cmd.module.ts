import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule, ConfigService } from '@nestjs/config';


// Shared Library Import (Correct Name based on your library definition)
import { SharedAuthModule } from '@dermatech/shared-guards';

// Local Components
import { Doctor } from './entities/doctor.entity';
import { DoctorController } from './controllers/doctor.controller';
import { Appointment } from './entities/appointment.entity'
import { BookAppointmentHandler } from './cqrs/commands/handlers/book-appointment.handler';
import { CreateDoctorHandler } from './cqrs/commands/handlers/create-doctor.handler';
import { AppointmentController } from './controllers/appointment.controller';

@Module({
  imports: [
    // 1. Configuration: Loads .env file globally
    ConfigModule.forRoot({ 
      isGlobal: true,
      envFilePath: 'apps/services/scheduling/appointment-cmd/.env', // Ensures it looks for the file
    }),

    // 2. Architecture & Security
    CqrsModule,
    SharedAuthModule, // CORRECTED: Matches the class name exported in your library

    // 3. Database Connection (Async to ensure Config is loaded first)
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USER', 'postgres'),
        password: config.get<string>('DB_PASSWORD', 'postgres'),
        database: config.get<string>('DB_NAME', 'postgres'),
        autoLoadEntities: true,
        synchronize: true, // Only for development/prototyping
      }),
    }),
    
    TypeOrmModule.forFeature([Doctor, Appointment]),
  ],
  controllers: [DoctorController, AppointmentController],
  providers: [CreateDoctorHandler, BookAppointmentHandler],
})
export class AppointmentCmdModule {}