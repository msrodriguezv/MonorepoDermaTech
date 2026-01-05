import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

/**
 * DTO: RefreshTokenDto
 * * Layer: Shared Interface Adapters (Contract)
 * * Usage: Used by clients to request a new Access Token using a valid Refresh Token.
 */
export class RefreshTokenDto {
  @ApiProperty({ 
    description: 'The Refresh Token issued during login (long-lived)', 
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' 
  })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}