

import { IsString, IsNotEmpty } from 'class-validator'; 
import { ApiProperty } from '@nestjs/swagger';

export class DerivePatientDto {

  
  @ApiProperty({ example: 'EST-12345', description: 'ID del estudiante' })
  @IsString()     
  @IsNotEmpty()  
  patientId: string;

  
  @ApiProperty({ example: 'DOC-MARIA', description: 'ID del doctor' })
  @IsString()
  @IsNotEmpty()
  doctorId: string;


  @ApiProperty({ example: 'HOSPITAL-METRO', description: 'ID del hospital destino' })
  @IsString()
  @IsNotEmpty()
  targetHospitalId: string;

  
  @ApiProperty({ example: 'Fractura', description: 'Motivo de derivación' })
  @IsString()
  @IsNotEmpty()
  reason: string;
}