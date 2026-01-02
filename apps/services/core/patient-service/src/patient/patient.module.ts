import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { ConfigModule, ConfigService } from '@nestjs/config'; // <--- Importante
import { CqrsModule } from '@nestjs/cqrs';

import { PatientsController } from './controllers/patient.controller';
import { PatientService } from './services/patient.service';
import { Patient } from './entities/patient.entity';
import { S3Service } from '../common/services/s3.service';
import { MedicalRecord } from './entities/medical-record.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Patient, MedicalRecord]),
    CqrsModule,

    ClientsModule.registerAsync([
      {
        name: 'PATIENT_KAFKA_CLIENT',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.KAFKA,
          options: {
            client: {
              clientId: 'patient-service',
              // FIX: Read brokers dynamically from environment variables
              // This supports both local ('localhost:9092') and Docker ('kafka:29092')
              brokers: (configService.get<string>('KAFKA_BROKERS') || 'localhost:9092')
                .split(',')
                .map((broker) => broker.trim()),
            },
            consumer: {
              groupId: 'patient-consumer',
            },
          },
        }),
      },
    ]),
  ],
  controllers: [PatientsController],
  providers: [PatientService, S3Service],
  exports: [PatientService],
})
export class PatientModule {}