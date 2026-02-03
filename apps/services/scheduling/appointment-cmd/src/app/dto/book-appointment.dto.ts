import { IsNotEmpty, IsUUID, IsISO8601, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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
    description: 'Brief description of symptoms for AI Triage', 
    example: 'Dolor de cabeza intenso y visión borrosa' 
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  readonly symptoms: string;
}