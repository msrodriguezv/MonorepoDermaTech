import { IsNotEmpty, IsUUID, IsISO8601 } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * DTO for Querying Availability.
 * Defines the contract for GET /availability requests.
 */
export class QueryAvailabilityDto {
  @ApiProperty({
    description: 'The Doctor UUID to check availability for',
    example: 'd8139c6f-a928-4b71-aa84-a51da3fbae34',
  })
  @IsUUID('4')
  @IsNotEmpty()
  readonly doctorId: string;

  @ApiProperty({
    description: 'The specific date to check (YYYY-MM-DD)',
    example: '2025-01-20',
  })
  @IsISO8601({ strict: true })
  @IsNotEmpty()
  readonly date: string;
}