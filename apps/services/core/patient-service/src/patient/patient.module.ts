import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientService } from './patient.service';
import { PatientController } from './patient.controller';
import { Patient } from './entities/patient.entity';
// CAMBIO: Usamos S3Service en lugar de SupabaseService
import { S3Service } from '../common/services/s3.service'; 

@Module({
  imports: [TypeOrmModule.forFeature([Patient])],
  controllers: [PatientController],
  providers: [
    PatientService, 
    S3Service // <--- Inyectamos el servicio de S3
  ],
  exports: [PatientService],
})
export class PatientModule {}