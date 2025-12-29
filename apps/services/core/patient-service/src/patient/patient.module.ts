import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
// Servicio en SINGULAR (PatientService)
import { PatientService } from './patient.service'; 
// Controlador en PLURAL (PatientsController)
import { PatientsController } from './patient.controller';
import { Patient } from './entities/patient.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Patient]) 
  ],
  controllers: [PatientsController], // <--- PLURAL
  providers: [PatientService],       // <--- SINGULAR
  exports: [PatientService]          // <--- SINGULAR
})
export class PatientsModule {}       // <--- PLURAL