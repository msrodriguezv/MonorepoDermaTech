import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../../enums/user-role.enum';

/**
 * Data Transfer Object for User Response.
 * Represents the public data of a User sent back to the client.
 * Decouples the Domain Entity (private logic) from the API Response.
 */
export class UserResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'student@uce.edu.ec' })
  email!: string;

  @ApiProperty({ enum: UserRole, example: UserRole.STUDENT })
  role!: UserRole;

  @ApiProperty({ example: true })
  isActive!: boolean;
}