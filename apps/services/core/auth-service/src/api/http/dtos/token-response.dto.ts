import { ApiProperty } from '@nestjs/swagger';

export class TokenResponseDto {
  @ApiProperty({ description: 'JWT Access Token used for authentication' })
  accessToken: string;

  @ApiProperty({ description: 'JWT Refresh Token used to obtain new access tokens' })
  refreshToken: string;

  @ApiProperty({ description: 'Expiration time of the access token in milliseconds' })
  expiresIn: number;
}