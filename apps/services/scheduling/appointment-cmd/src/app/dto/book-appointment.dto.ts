import { IsNotEmpty, IsUUID, IsISO8601 } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Data Transfer Object for Booking an Appointment.
 * Note: strictUser (Student) ID is NOT included here for security.
 * It will be extracted from the JWT in the Controller.
 */
export class BookAppointmentDto {
  
  @ApiProperty({ 
    description: 'The UUID of the Doctor to book', 
    example: 'd19283-uuid-4444-5555' 
  })
  @IsUUID()
  @IsNotEmpty()
  readonly doctorId: string;

  @ApiProperty({ 
    description: 'Start time of the appointment (ISO 8601)', 
    example: '2024-01-20T10:00:00Z' 
  })
  @IsISO8601()
  @IsNotEmpty()
  readonly startTime: string;

  // Ideally, duration is fixed (e.g., 30 mins) or calculated, 
  // but we can accept endTime if flexible slots are allowed.
  // For this MVP, we assume the frontend sends the calculated end time.
  @ApiProperty({ 
    description: 'End time of the appointment (ISO 8601)', 
    example: '2024-01-20T10:30:00Z' 
  })
  @IsISO8601()
  @IsNotEmpty()
  readonly endTime: string;
}