import { IsString, IsEmail, IsUUID, IsArray, IsOptional, IsObject } from 'class-validator'; // <--- Importamos IsObject
import { ApiProperty } from '@nestjs/swagger';

export class CreatePatientDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'juan.perez@uce.edu.ec' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Juan' })
  @IsString()
  firstName: string;

  @ApiProperty({ example: 'Perez' })
  @IsString()
  lastName: string;

  @ApiProperty({ example: '1990-01-01' })
  @IsString()
  birthDate: string;

  @ApiProperty({ example: '0987654321' })
  @IsString()
  phone: string;

  @ApiProperty({ 
    example: { bloodType: 'O+', chronicConditions: ['Diabetes'] },
    description: 'Medical details as a JSON object (blood type, etc.)'
  })
  @IsObject()   
  @IsOptional() 
  medicalInfo: Record<string, any>; 

  @ApiProperty({ example: ['Penicilina'] })
  @IsArray()
  @IsString({ each: true })
  allergies: string[];
    
  @ApiProperty({ example: 'IESS', required: false })
  @IsString()
  @IsOptional()
  insuranceProvider?: string;
}