import { IsEmail, IsEnum, IsNotEmpty, MinLength, Matches } from 'class-validator';
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
    example: 'StrongP@ssw0rd!',
    description: 'The user password. Must contain at least 8 characters, one uppercase, one number, and one special character.',
    minLength: 8,
  })
  @MinLength(8)
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, {
    message: 'Password must contain uppercase, lowercase, number and special character',
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