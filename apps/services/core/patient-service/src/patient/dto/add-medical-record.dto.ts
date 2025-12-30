import { IsString, IsNotEmpty, IsUrl } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddMedicalRecordDto {
  @ApiProperty({ description: 'URL of the lesion photo (from Supabase Storage)', example: 'https://supabase.../lesion1.jpg' })
  @IsString()
  @IsNotEmpty()
  photoUrl: string;

  @ApiProperty({ description: 'Reason for the appointment', example: 'I have a red spot that hurts.' })
  @IsString()
  @IsNotEmpty()
  description: string;
}