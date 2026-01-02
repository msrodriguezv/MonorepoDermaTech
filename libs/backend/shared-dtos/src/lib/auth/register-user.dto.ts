import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, MinLength, Matches, IsEnum } from 'class-validator';
import { UserRole } from '../../enums/user-role.enum';
import { BaseAuthDto } from '../../common/base-auth.dto'

/**
 * Data Transfer Object for User Registration.
 * Enforces strict password policies to ensure account security upon creation.
 */
export class RegisterUserDto extends BaseAuthDto {
  @ApiProperty({ 
    example: 'StrongP@ss1!', 
    description: 'Password meeting security policies (min 8 chars, uppercase, symbol)',
    writeOnly: true
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(8, { message: 'Password must be at least 8 characters long.' })
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, { 
    message: 'Password is too weak. It must contain uppercase, lowercase, number or special character.' 
  })
  password!: string;

  @ApiProperty({ 
    enum: UserRole, 
    example: UserRole.STUDENT,
    description: 'Initial role assigned to the user'
  })
  @IsEnum(UserRole)
  @IsNotEmpty()
  role!: UserRole;
}