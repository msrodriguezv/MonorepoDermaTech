import { IsString, IsNotEmpty, IsUUID, Length, IsBoolean, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Data Transfer Object for creating a new Doctor Profile.
 * Represents the payload required by the Admin to register a medical professional.
 */
export class CreateDoctorDto {
  @ApiProperty({ 
    description: 'The User ID (Auth Service) to be promoted to Doctor', 
    example: 'd8139c6f-a928-4b71-aa84-a51da3fbae34' 
  })
  @IsUUID()
  @IsNotEmpty()
  readonly userId: string;

  @ApiProperty({ description: 'First Name', example: 'Gregory' })
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  readonly firstName: string;

  @ApiProperty({ description: 'Last Name', example: 'House' })
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  readonly lastName: string;

  @ApiProperty({ description: 'Medical Specialization', example: 'Diagnostic Medicine' })
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  readonly specialization: string;

  @ApiProperty({ description: 'Professional License Number', example: 'MED-555-EC' })
  @IsString()
  @IsNotEmpty()
  @Length(5, 50)
  readonly licenseNumber: string;

  @ApiProperty({ description: 'Physical Office Number', example: 'Box 101', required: false })
  @IsString()
  @IsOptional()
  readonly officeNumber?: string;

  @ApiProperty({ description: 'Is the doctor active immediately?', default: true, required: false })
  @IsBoolean()
  @IsOptional()
  readonly isActive?: boolean;
}