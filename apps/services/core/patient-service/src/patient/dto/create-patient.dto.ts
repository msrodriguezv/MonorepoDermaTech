import { 
  IsEmail, 
  IsString, 
  Length, 
  Matches, 
  IsMobilePhone, 
  IsOptional, 
  IsArray, 
  IsUUID 
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePatientDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  userId: string;

  

  @ApiProperty({ example: 'juan.perez@uce.edu.ec' })
  @IsEmail({}, { message: 'El formato del correo es inválido' })
  @Matches(/@uce\.edu\.ec$/, { 
    message: 'Solo se permiten correos institucionales (@uce.edu.ec)' 
  })
  email: string;

 


  
  @ApiProperty({ example: 'Juan' })
  @IsString()
  firstName: string;

  @ApiProperty({ example: 'Perez' })
  @IsString()
  lastName: string;

  @ApiProperty({ example: '1990-01-01' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { 
    message: 'La fecha de nacimiento debe tener el formato AAAA-MM-DD' 
  })
  birthDate: string;

  @ApiProperty({ example: '0987654321' })
  @IsString()
  @Matches(/^09[0-9]{8}$/, { 
    message: 'El celular debe empezar con 09 y tener 10 números' 
  })
  phone: string;

@ApiProperty({ example: 'O+' })
  @IsString({ message: 'La información médica debe ser un texto' })
  medicalInfo: any; 

  @ApiProperty({ example: ['Penicilina'], isArray: true })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  allergies: string[];
}