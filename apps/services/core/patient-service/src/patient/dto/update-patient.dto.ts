import { IsString, IsOptional, IsDateString, IsObject } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdatePatientDto {
  @ApiProperty({ example: 'Juan', description: 'Nombre del paciente' })
  @IsString()
  @IsOptional()
  firstName?: string;

  @ApiProperty({ example: 'Perez', description: 'Apellido del paciente' })
  @IsString()
  @IsOptional()
  lastName?: string;

  @ApiProperty({ example: '1990-01-01', description: 'Fecha de nacimiento ISO 8601' })
  @IsDateString()
  @IsOptional()
  birthDate?: string;

  @ApiProperty({ example: '555-1234' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: { bloodType: 'O+', allergies: ['Penicilina'] } })
  @IsObject()
  @IsOptional()
  medicalInfo?: {
    bloodType: string;
    allergies: string[];
    chronicConditions: string[];
  };
}