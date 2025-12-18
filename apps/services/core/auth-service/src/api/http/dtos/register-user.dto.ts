import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  MinLength,
  Matches,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@dermatech/shared-dtos';

/**
 * Data Transfer Object for User Registration.
 * Defines the expected shape of the JSON body for the POST /auth/register endpoint.
 * Includes validation rules (class-validator) and documentation (Swagger).
 */
export class RegisterUserDto {
  @ApiProperty({
    example: 'student@uce.edu.ec',
    description: 'The email address of the user. Must be unique.',
  })
  @IsEmail({}, { message: 'Invalid email format' })
  @IsNotEmpty()
  email: string;

  @ApiProperty({
    example: 'StrongP@ssw0rd1',
    description: 'Min 8 chars, 1 upper, 1 lower, 1 number, 1 special char',
  })
  @MinLength(8)
  // FIX: Estrict mode regex
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/, {
    message:
      'Password must contain at least: 1 uppercase, 1 lowercase, 1 number, and 1 special character',
  })
  password: string;

  @ApiProperty({
    enum: UserRole,
    example: UserRole.STUDENT,
    description: 'The role assigned to the user.',
  })
  @IsEnum(UserRole, { message: 'Invalid role provided' })
  @IsNotEmpty()
  role: UserRole;
}
