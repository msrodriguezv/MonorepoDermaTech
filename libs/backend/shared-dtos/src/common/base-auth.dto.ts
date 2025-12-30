import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty } from 'class-validator';

/**
 * Base Data Transfer Object for Authentication.
 * Centralizes the email structure and validation logic to be reused
 * across different authentication contexts (Login, Register, etc.).
 */
export class BaseAuthDto {
  @ApiProperty({ 
    example: 'user@uce.edu.ec', 
    description: 'User email address used as unique identifier',
    format: 'email'
  })
  @IsEmail({}, { message: 'The provided email is not valid according to standard RFC formats.' })
  @IsNotEmpty()
  email!: string;
}