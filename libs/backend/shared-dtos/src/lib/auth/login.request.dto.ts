import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';
import { BaseAuthDto } from '../../common/base-auth.dto'; 

/**
 * Data Transfer Object for the Login request.
 * Extends BaseAuthDto to inherit strict email validation.
 * Password validation is intentionally minimal to avoid leaking security policies during authentication.
 */
export class LoginRequestDto extends BaseAuthDto {
  @ApiProperty({ 
    example: 'StrongP@ss1!', 
    description: 'User password provided during registration',
    writeOnly: true
  })
  @IsString()
  @IsNotEmpty()
  password!: string;
}