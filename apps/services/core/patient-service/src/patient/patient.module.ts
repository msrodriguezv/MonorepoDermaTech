import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';

import { PatientService } from './services/patient.service';
import { PatientsController } from './controllers/patient.controller';
import { Patient } from './entities/patient.entity';
// --- 1. IMPORTAR LA NUEVA ENTIDAD ---
import { MedicalRecord } from './entities/medical-record.entity';

// Ajusté las rutas relativas para que sean más limpias (./), verifica si tu carpeta auth está ahí
import { JwtStrategy } from '../app/auth/jwt.strategy';
import { CreatePatientHandler } from './cqrs/create-patient.handler';
// --- 2. IMPORTAR EL NUEVO HANDLER ---
import { AddMedicalRecordHandler } from './cqrs/add-medical-record.handler';

@Module({
  imports: [
    CqrsModule,
    
    // --- 3. REGISTRAR AMBAS ENTIDADES AQUÍ ---
    // Esto permite inyectar Repository<Patient> y Repository<MedicalRecord>
    TypeOrmModule.forFeature([Patient, MedicalRecord]), 

    // --- SEGURITY JWT ---
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: 'SUPER_SECRET_KEY_TESIS_2025',
      signOptions: { expiresIn: '1h' },
    }),

    // --- KAFKA (FAIL-SAFE) ---
    ClientsModule.register([
      {
        name: 'PATIENT_KAFKA_CLIENT',
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: 'patient-service',
            brokers: ['localhost:9092'],
            connectionTimeout: 3000,
            retry: { retries: 1 },
          },
          consumer: { groupId: 'patient-consumer-group' },
        },
      },
    ]),
  ],
  controllers: [PatientsController],

  // --- 4. AGREGAR EL NUEVO HANDLER A LOS PROVIDERS ---
  providers: [
    PatientService,
    JwtStrategy,
    CreatePatientHandler,
    AddMedicalRecordHandler // <--- ESENCIAL: Sin esto, el CommandBus fallará
  ],
})
export class PatientsModule {}