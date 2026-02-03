import { ApiProperty } from '@nestjs/swagger';

export class AvailabilityResponseDto {
  @ApiProperty({ example: 'uuid-doctor' })
  doctorId: string;

  @ApiProperty({ example: '2025-02-02' })
  date: string;

  @ApiProperty({ example: 14 })
  totalSlots: number;

  @ApiProperty({ example: 2 })
  takenSlotsCount: number;

  @ApiProperty({ example: ['09:00', '10:30'], type: [String] })
  availableSlots: string[];
}