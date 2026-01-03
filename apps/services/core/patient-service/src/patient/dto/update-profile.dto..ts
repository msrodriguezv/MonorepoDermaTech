import { IsString, IsNotEmpty, IsOptional, IsArray, IsDateString, IsUrl } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * UpdateProfileDto
 * * This Data Transfer Object (DTO) defines the strict contract for the data payload 
 * required when a user (Student) completes or updates their profile via the REST API.
 * * It serves two main technical purposes:
 * 1. Validation: Uses 'class-validator' decorators to ensure data integrity before it reaches the Service layer.
 * 2. Documentation: Uses '@nestjs/swagger' decorators to automatically generate the OpenAPI (Swagger) specification.
 */
export class UpdateProfileDto {

  @ApiProperty({ 
    example: 'Juan', 
    description: 'The legal first name of the patient.' 
  })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({ 
    example: 'Perez', 
    description: 'The legal last name of the patient.' 
  })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiProperty({ 
    example: '1999-05-20', 
    description: 'Date of birth in ISO 8601 format (YYYY-MM-DD). Required for medical triage.' 
  })
  @IsNotEmpty()
  @IsDateString()
  birthDate: string; // We receive it as string, the Service/TypeORM will cast it to Date.

  @ApiProperty({ 
    example: '+593991234567', 
    description: 'Contact phone number. Necessary for emergency contacts.' 
  })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ 
    example: 'https://my-bucket.s3.amazonaws.com/avatar.jpg', 
    description: 'Public URL of the profile picture stored in S3.',
    required: false
  })
  @IsOptional()
  @IsString()
  @IsUrl()
  avatarUrl?: string;

  @ApiProperty({ 
    example: 'IESS', 
    description: 'Name of the insurance provider.', 
    required: false 
  })
  @IsOptional()
  @IsString()
  insuranceProvider?: string;

  // --- Medical Info Section (Mapped to JSONB in Entity) ---

  @ApiProperty({ 
    example: 'O+', 
    description: 'Blood type of the patient.', 
    required: false 
  })
  @IsOptional()
  @IsString()
  bloodType?: string;

  @ApiProperty({ 
    example: ['Penicillin', 'Peanuts'], 
    description: 'List of known allergies.', 
    required: false,
    isArray: true
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true }) // Validates that every item in the array is a string
  allergies?: string[];

  @ApiProperty({ 
    example: ['Asthma', 'Diabetes'], 
    description: 'List of pre-existing chronic conditions.', 
    required: false,
    isArray: true
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  chronicConditions?: string[];
}