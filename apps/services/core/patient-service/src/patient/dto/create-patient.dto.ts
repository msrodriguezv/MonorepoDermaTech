import { IsString, IsDateString, IsOptional, Length, IsUUID, IsEmail, ValidateNested, IsArray } from 'class-validator';
import { Type } from 'class-transformer'; // Necesario para validar objetos anidados
import { ApiProperty } from '@nestjs/swagger';

// Sub-clase para validar el JSON interno
class MedicalInfoDto {
  @ApiProperty({ example: 'O+' })
  @IsString()
  @IsOptional()
  bloodType?: string;

  @ApiProperty({ example: ['Penicilina', 'Polvo'] })
  @IsArray()
  @IsString({ each: true }) // Valida que cada item del array sea string
  @IsOptional()
  allergies?: string[];

  @ApiProperty({ example: ['Asma'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  chronicConditions?: string[];
}

export class CreatePatientDto {
  @ApiProperty({ example: 'uuid-del-auth-service' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'usuario@email.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Juan' })
  @IsString()
  @Length(2, 100)
  firstName: string;

  @ApiProperty({ example: 'Perez' })
  @IsString()
  @Length(2, 100)
  lastName: string;

  @ApiProperty({ example: '1990-01-01' })
  @IsDateString()
  birthDate: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  phone?: string;

  // VALIDACIÓN DEL JSONB
  @ApiProperty({ type: MedicalInfoDto, required: false })
  @IsOptional()
  @ValidateNested() // Valida el objeto por dentro
  @Type(() => MedicalInfoDto) // Convierte el JSON plano a la clase MedicalInfoDto
  medicalInfo?: MedicalInfoDto;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  insuranceProvider?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}