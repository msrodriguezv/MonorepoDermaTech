import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../../enums/user-role.enum'; 

export class UserPayloadDto {
  @ApiProperty({ description: 'Unique identifier of the user', example: '550e8400-e29b-41d4-a716-446655440000' })
  id!: string;

  @ApiProperty({ description: 'User email address', example: 'doctor@dermatech.com' })
  email!: string;

  @ApiProperty({ description: 'User role within the system', enum: UserRole, example: UserRole.DOCTOR })
  role!: UserRole;
}

export class TokenResponseDto {
  @ApiProperty({ description: 'JWT Access Token used for authentication' })
  accessToken!: string;

  @ApiProperty({ description: 'JWT Refresh Token used to obtain new access tokens' })
  refreshToken!: string;

  @ApiProperty({ description: 'Expiration time of the access token in milliseconds' })
  expiresIn!: number;

  @ApiProperty({ description: 'Basic information of the authenticated user', type: UserPayloadDto })
  user!: UserPayloadDto;
}