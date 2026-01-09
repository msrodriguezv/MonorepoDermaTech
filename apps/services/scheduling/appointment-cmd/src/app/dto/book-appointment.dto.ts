import { IsNotEmpty, IsUUID, IsISO8601 } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Data Transfer Object for Booking an Appointment.
 * Note: The Student ID is NOT included here for security (extracted from JWT).
 */
export class BookAppointmentDto {
  
  @ApiProperty({ 
    description: 'The UUID of the Doctor to book', 
    example: 'd19283-uuid-4444-5555' 
  })
  @IsUUID('4')
  @IsNotEmpty()
  readonly doctorId: string;

  @ApiProperty({ 
    description: 'Start time of the appointment (ISO 8601 format)', 
    example: '2024-01-20T10:00:00.000Z' 
  })
  @IsISO8601()
  @IsNotEmpty()
  readonly startTime: string;

  @ApiProperty({ 
    description: 'End time of the appointment (ISO 8601 format)', 
    example: '2024-01-20T10:30:00.000Z' 
  })
  @IsISO8601()
  @IsNotEmpty()
  readonly endTime: string;
}