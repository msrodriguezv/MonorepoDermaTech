// 📂 apps/services/support/external-partners/src/dto/derive-patient.dto.ts

import { IsString, IsNotEmpty } from 'class-validator'; // <--- ESTO ES OBLIGATORIO
import { ApiProperty } from '@nestjs/swagger';

export class DerivePatientDto {
  
  // 1. Validamos Patient ID
  @ApiProperty({ example: 'EST-12345', description: 'ID del estudiante' })
  @IsString()    // <--- Si falta esto, da error 400
  @IsNotEmpty()  // <--- Si falta esto, da error 400
  patientId: string;

  // 2. Validamos Doctor ID
  @ApiProperty({ example: 'DOC-MARIA', description: 'ID del doctor' })
  @IsString()
  @IsNotEmpty()
  doctorId: string;

  // 3. Validamos Hospital ID
  @ApiProperty({ example: 'HOSPITAL-METRO', description: 'ID del hospital destino' })
  @IsString()
  @IsNotEmpty()
  targetHospitalId: string;

  // 4. Validamos Razón
  @ApiProperty({ example: 'Fractura', description: 'Motivo de derivación' })
  @IsString()
  @IsNotEmpty()
  reason: string;
}