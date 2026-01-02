import { IsString, IsNotEmpty } from 'class-validator'; 

export class AddMedicalRecordDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  description: string;
  
}